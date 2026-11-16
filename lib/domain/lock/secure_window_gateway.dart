/// Native window privacy behind the Flutter privacy overlay (D-04,
/// RESEARCH Pattern 7).
///
/// On Android it toggles `FLAG_SECURE`, which blanks screenshots, screen
/// recording and the Recents thumbnail. On iOS it arms the opaque cover the
/// scene delegate places over the window before the App Switcher snapshot.
///
/// Implementations live in `lib/infrastructure/lock/`.
// A one-method interface on purpose: the domain seam lets tests and later
// plans (05-12 PinLifecycle) mock the platform channel.
// ignore: one_member_abstracts
abstract interface class SecureWindowGateway {
  /// Enables or disables the native shield.
  ///
  /// Never throws: returns true when the platform applied the change, and
  /// false on unsupported platforms or when the channel call fails.
  Future<bool> setSecure({required bool enabled});
}
