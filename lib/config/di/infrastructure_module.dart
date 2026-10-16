import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:injectable/injectable.dart';

/// DI registrations for infrastructure services
/// (notifications, backup, app lock).
///
/// Holds third-party platform objects the services need. Kept separate from
/// domain modules because infrastructure services depend on Flutter platform
/// channels and must not leak into the domain or data layers. The notification
/// services themselves self-register through `@LazySingleton(as: ...)`.
@module
abstract class InfrastructureModule {
  /// The single plugin instance shared by the gateway and the permission
  /// service.
  @lazySingleton
  FlutterLocalNotificationsPlugin get notificationsPlugin =>
      FlutterLocalNotificationsPlugin();
}
