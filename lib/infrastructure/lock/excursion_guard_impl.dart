import 'package:agenda/domain/lock/excursion_guard.dart';
import 'package:injectable/injectable.dart';

/// In-memory [ExcursionGuard]: a counter of in-flight runs plus a [grace]
/// window after the last one ends.
///
/// The grace covers platforms that complete the future before delivering
/// `resumed`, and fire-and-forget calls such as opening the notification
/// settings, which return as soon as the other screen starts (RESEARCH
/// Assumption A3: 2 s, tuned in device UAT).
@LazySingleton(as: ExcursionGuard)
class ExcursionGuardImpl implements ExcursionGuard {
  ExcursionGuardImpl({@ignoreParam DateTime Function()? clock})
    : _clock = clock ?? DateTime.now;

  /// How long an excursion stays active after its action completes.
  static const Duration grace = Duration(seconds: 2);

  final DateTime Function() _clock;

  int _inFlight = 0;
  DateTime? _lastEndedAt;

  @override
  Future<T> run<T>(Future<T> Function() action) async {
    _inFlight++;
    try {
      return await action();
    } finally {
      _inFlight--;
      _lastEndedAt = _clock();
    }
  }

  @override
  bool isActive(DateTime now) {
    if (_inFlight > 0) return true;
    final ended = _lastEndedAt;
    if (ended == null) return false;
    return !now.isAfter(ended.add(grace));
  }
}
