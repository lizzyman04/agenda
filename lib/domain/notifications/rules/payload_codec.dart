import 'package:agenda/domain/notifications/model/notification_kind.dart';

const int _maxPayloadLength = 64;
const String _version = 'v1';
final RegExp _digits = RegExp(r'^\d{1,18}$');

/// A decoded tap payload.
final class NotificationPayload {
  const NotificationPayload({
    required this.kind,
    required this.entityId,
    required this.fireEpochSec,
    required this.exact,
  });

  final NotificationKind kind;
  final int entityId;
  final int fireEpochSec;
  final bool exact;
}

/// Encodes `v1|<code>|<entityId>|<fireEpochSec>|<e or i>`.
String encodePayload({
  required NotificationKind kind,
  required int entityId,
  required DateTime fireAt,
  required bool exact,
}) {
  final seconds = fireAt.millisecondsSinceEpoch ~/ 1000;
  return '$_version|${kind.code}|$entityId|$seconds|${exact ? 'e' : 'i'}';
}

/// Decodes a payload the platform handed back on tap.
///
/// The string is untrusted: length cap, exactly five fields, version and
/// kind whitelist, non-negative integers and a known mode. Anything else
/// returns null and the caller simply opens the app. Never throws.
NotificationPayload? decodePayload(String? raw) {
  if (raw == null || raw.isEmpty || raw.length > _maxPayloadLength) {
    return null;
  }
  final parts = raw.split('|');
  if (parts.length != 5 || parts[0] != _version) return null;
  final kind = NotificationKind.fromCode(parts[1]);
  if (kind == null) return null;
  if (!_digits.hasMatch(parts[2]) || !_digits.hasMatch(parts[3])) return null;
  final mode = parts[4];
  if (mode != 'e' && mode != 'i') return null;
  final entityId = int.tryParse(parts[2]);
  final seconds = int.tryParse(parts[3]);
  if (entityId == null || seconds == null) return null;
  return NotificationPayload(
    kind: kind,
    entityId: entityId,
    fireEpochSec: seconds,
    exact: mode == 'e',
  );
}
