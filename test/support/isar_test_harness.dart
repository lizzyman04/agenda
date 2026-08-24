// Real-Isar test harness for `flutter test`.
//
// This project's test suite has never opened a real `isar_community`
// instance before this file — every existing test either mocks the
// repository/DAO layer or drives a `FakeIsar extends Fake implements Isar`
// (see `test/data/database/migration_runner_test.dart`). That is not enough
// to catch defects that live *inside* a DAO's query shape (for example,
// `.limit(500)` applied without a `sortBy` — see BL-01 in
// `.planning/phases/03-finance-core/03-REVIEW.md`), because a mocked
// repository never runs the query at all. `IsarTestHarness` opens a genuine
// `isar_community` database against an isolated temp directory so tests can
// exercise real query behavior, then tears it down cleanly.
//
// --------------------------------------------------------------------------
// Decision 1 — binary acquisition route.
// --------------------------------------------------------------------------
// Route taken: download-on-demand via `Isar.initializeIsarCore(download:
// true)`, called once per test process behind an idempotency guard
// (`_coreInitialized` below), NOT a vendored/committed native binary.
//
// Rationale: `Isar.initializeIsarCore(download: true)` is isar_community's
// own documented mechanism for opening Isar outside a running Flutter app.
// It requires zero repository changes, and the binary it fetches is cached
// by the package itself, so only the *first* invocation on a given machine
// needs network access. A vendored binary was considered and rejected: it
// would require committing a platform-specific native library (`.so` /
// `.dylib` / `.dll`) obtained by actually running the download once —
// something a planning-only pass cannot do — and it would silently drift
// from whatever `isar_community` version is pinned in `pubspec.yaml`.
//
// Residual risk (explicit, not silently assumed): on a machine or CI runner
// with no cached Isar Core binary AND no network access, the first
// `flutter test` run that touches this harness will fail at
// `initializeIsarCore` with a download/network error. This is a
// dev-toolchain limitation, not a violation of CLAUDE.md's privacy/offline
// constraint — that constraint governs the shipped app's runtime behavior,
// and the shipped app (`lib/data/database/isar_service.dart`) never calls
// this method.
//
// --------------------------------------------------------------------------
// Decision 2 — the concurrent-download race, the Platform.script path
// mismatch this plan already got wrong once, and why the fix must be a
// `flutter test` invocation.
// --------------------------------------------------------------------------
// The race, named precisely: `isar_community` 3.3.2's `_downloadIsarCore`
// (`lib/src/native/isar_core.dart`) is a bare check-then-act — it checks
// whether the destination file exists, and if not, streams the download
// straight to that final path, with no lock file and no atomic
// temp-file-then-rename. Two processes racing that write can corrupt the
// native library both then load via `DynamicLibrary.open()`. The package's
// own doc comment says outright to always use `flutter test -j 1` when
// relying on auto-download for exactly this reason. This project's
// `_coreInitialized` guard below is per-process and CANNOT fix a
// cross-process race, because `flutter test` runs each test file as a
// separate OS process by default.
//
// The path-resolution fact, the non-obvious detail that broke this plan's
// first attempt: `_getLibraryDownloadPath` derives the download directory
// from `Platform.script`'s parent directory, and `Platform.script` resolves
// differently depending on invocation mechanism. Running
// `dart run tool/some_script.dart` resolves `Platform.script` to that
// script's own path, so the binary is cached under that script's directory
// (e.g. `tool/`). Running `flutter test` resolves `Platform.script` to a
// synthetic `<repo>/main.dart` entrypoint shared by every test worker, so
// the binary is cached under the repo root instead. A `dart run`-based
// pre-warm step therefore writes to a directory the later `flutter test`
// workers never check — this plan's first mitigation attempt did exactly
// that (`dart run tool/warm_isar_core.dart`) and was a documented no-op;
// the race it was meant to prevent still occurred on every cold-cache run.
//
// The fix, and why it structurally holds: the CI pre-warm step is itself a
// `flutter test` invocation — `test/support/_warm_isar_core_test.dart`, run
// via `flutter test --no-pub -j 1 test/support/_warm_isar_core_test.dart`
// as its own CI step, strictly before the main `Test` step. Because both
// the pre-warm step and the main `Test` step invoke through `flutter test`,
// both resolve `Platform.script` — and therefore the download path — the
// same way. This is a structural guarantee, not two independently
// maintained paths someone has to keep in sync by hand. If the pre-warm
// step is ever changed back to a `dart run` invocation, the path mismatch —
// and the race — return silently, with every existing acceptance criterion
// about step *ordering* still passing, because ordering was never the
// broken part.
//
// Options considered:
//   (a) pre-warm via a `flutter test` invocation before the main test
//       step's fan-out — CHOSEN, for the structural path-agreement reason
//       above.
//   (b) pin the whole CI run to `flutter test -j 1`, serializing all tests —
//       rejected, pays a wall-clock cost on every run to fix something that
//       only needs to happen once per machine.
//   (c) an explicit `libraries:` map in the harness pointing both the
//       pre-warm step and the harness at one fixed, hand-specified path —
//       rejected, because it requires two independently-derived locations
//       to stay aligned forever, the same class of bug that broke the
//       `dart run` attempt in the first place.
//
// Local-dev note: a developer running `flutter test` locally with
// concurrency > 1 across multiple harness-using files, on a machine with no
// cached binary and without ever having run the pre-warm test file, can
// still hit this race. The fix is running
// `flutter test --no-pub -j 1 test/support/_warm_isar_core_test.dart` once,
// or `flutter test -j 1` generally, the first time.

import 'dart:io';

import 'package:isar_community/isar.dart';

/// Per-process guard so [IsarTestHarness.open] only calls
/// `Isar.initializeIsarCore` once. Does NOT protect against the
/// cross-process download race described above — that is mitigated by the
/// CI pre-warm step instead.
bool _coreInitialized = false;

/// Monotonic per-process counter backing each harness instance's Isar
/// name. Used instead of a wall-clock timestamp (see IN-01 in
/// `03-REVIEW.md`) so uniqueness never depends on clock resolution.
int _instanceCounter = 0;

/// Opens a real `isar_community` [Isar] instance against an isolated,
/// per-call temp directory, for use in `flutter test`.
///
/// See this file's top-of-file doc comment for the binary-acquisition
/// decision and the concurrent-download race mitigation.
class IsarTestHarness {
  Isar? _isar;
  Directory? _tempDir;

  /// The currently open instance, or null if [open] has not been called
  /// (or [close] has already run).
  Isar? get isar => _isar;

  /// The temp directory backing the currently open instance, or null.
  ///
  /// Exposed so callers can assert on cleanup without introspecting the
  /// [Isar] instance's own directory API.
  Directory? get tempDir => _tempDir;

  /// Opens a fresh Isar instance for [schemas] against a new temp
  /// directory.
  ///
  /// Throws [StateError] if this harness already has an instance open —
  /// call [close] first, or use a fresh [IsarTestHarness]. The temp
  /// directory is recorded before `Isar.open()` is awaited, so a failed
  /// open still leaves [close] able to remove it.
  Future<Isar> open(List<CollectionSchema<dynamic>> schemas) async {
    if (_isar != null) {
      throw StateError(
        'IsarTestHarness.open() called twice on the same instance: '
        'call close() before reopening, or use a fresh IsarTestHarness.',
      );
    }
    if (!_coreInitialized) {
      await Isar.initializeIsarCore(download: true);
      _coreInitialized = true;
    }
    final dir = Directory.systemTemp.createTempSync('agenda_isar_test_');
    _tempDir = dir;
    final name = 'test_${_instanceCounter++}';
    final isar = await Isar.open(schemas, directory: dir.path, name: name);
    _isar = isar;
    return isar;
  }

  /// Closes the open instance (deleting its data from disk) and removes the
  /// backing temp directory. Idempotent — safe to call more than once, and
  /// safe to call without a prior [open].
  Future<void> close() async {
    await _isar?.close(deleteFromDisk: true);
    if (_tempDir?.existsSync() ?? false) {
      _tempDir!.deleteSync(recursive: true);
    }
    _isar = null;
    _tempDir = null;
  }
}
