import 'package:injectable/injectable.dart';

/// DI registrations for infrastructure services
/// (notifications, backup, app lock).
///
/// Populated in Phases 4-5. Kept separate from domain modules because
/// infrastructure services depend on Flutter platform channels and must not
/// leak into the domain or data layers.
@module
abstract class InfrastructureModule {}
