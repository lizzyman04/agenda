// Documented, justified allowlist of files/directories exempted from the
// architecture guard's checks (see `tool/check_architecture.dart`).
//
// An exemption without a written justification is a rule with a hole in it —
// every entry here must explain *why* the file/directory is exempt, not just
// *that* it is. See `.planning/phases/03.1-architecture-compliance/
// 03.1-RESEARCH.md`, "Split-or-Exempt Recommendations".

/// Files exempted from the 150-line-per-file cap, keyed by their path
/// relative to the repo root (posix-style, `/`-separated).
///
/// Each value is a mandatory justification string explaining why splitting
/// the file would hurt more than it helps. Keep this list short and
/// reviewed — an exemption is a deliberate, documented exception, not an
/// escape hatch for deferring a split that should actually happen.
const Map<String, String> lineLimitExemptions = {
  'lib/core/constants/currencies.dart':
      'Flat ISO 4217 data table (single static const List<Currency>) — '
      'splitting by line range fragments a single semantic unit and '
      'destroys Ctrl+F lookup for a currency code, for zero readability '
      'gain. See 3.1-RESEARCH.md Split-or-Exempt Recommendations.',
};

/// Directories exempted from the README-presence check, keyed by their path
/// relative to the repo root (posix-style, `/`-separated).
///
/// Empty per the README-scope decision recorded in 03.1-01-PLAN.md: every
/// directory under `lib/presentation/` and `lib/application/` requires a
/// README.md, with no exemptions.
const Set<String> readmeExemptDirs = {};
