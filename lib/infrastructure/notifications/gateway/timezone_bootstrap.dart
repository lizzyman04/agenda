import 'package:agenda/core/failures/failure.dart';
import 'package:agenda/core/failures/result.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Points the `timezone` package at the device's current zone.
///
/// Scheduled notifications are resolved in `tz.local`, which defaults to UTC
/// and so would fire at the wrong wall-clock time until this runs. Call it on
/// every cold start and again on resume, since the user can change zones
/// while the app is closed.
///
/// Returns the IANA identifier on success. Never throws: on any failure the
/// local zone is set to UTC and an [Err] carrying a [NotificationFailure] is
/// returned, so the caller can record the problem and carry on.
Future<Result<String>> bootstrapTimezone() async {
  try {
    tzdata.initializeTimeZones();
    final info = await FlutterTimezone.getLocalTimezone();
    tz.setLocalLocation(tz.getLocation(info.identifier));
    return Success(info.identifier);
  } on Object catch (error) {
    tz.setLocalLocation(tz.UTC);
    return Err(
      NotificationFailure(
        'Timezone bootstrap failed (${error.runtimeType}); using UTC',
      ),
    );
  }
}
