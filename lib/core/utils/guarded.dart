/// Awaits [action] and answers [fallback] if it throws, synchronously or
/// asynchronously.
///
/// For fail-closed callers that must turn any error into a known safe value
/// (the lock screen treats a failed check as "still locked").
Future<T> guarded<T>(Future<T> Function() action, T fallback) async {
  try {
    return await action();
  } on Object {
    return fallback;
  }
}
