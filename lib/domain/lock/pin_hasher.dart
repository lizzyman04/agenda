import 'package:agenda/domain/lock/pin_record.dart';

/// Number of digits in an app-lock PIN (D-05).
const int pinLength = 4;

/// Whether [pin] is exactly [pinLength] ASCII digits.
bool isValidPin(String pin) {
  if (pin.length != pinLength) return false;
  for (final unit in pin.codeUnits) {
    if (unit < 0x30 || unit > 0x39) return false;
  }
  return true;
}

/// Derives and checks salted PIN hashes (D-05).
///
/// Implementations live in `lib/infrastructure/lock/`. Hashing runs off the
/// UI isolate and the comparison is constant time.
abstract interface class PinHasher {
  /// A new record for [pin] with a fresh random salt.
  ///
  /// Throws [ArgumentError] when [pin] fails [isValidPin].
  Future<PinRecord> create(String pin);

  /// Whether [pin] matches [record]. False for any invalid [pin].
  Future<bool> verify(String pin, PinRecord record);
}
