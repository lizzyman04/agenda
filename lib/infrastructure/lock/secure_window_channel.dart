import 'package:agenda/domain/lock/secure_window_gateway.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';

/// Platform channel for the native privacy shield; the Kotlin and Swift
/// handlers must use the same names (pinned by secure_window_channel_test
/// and lock_platform_contract_test).
const String appPrivacyChannelName = 'agenda/app_privacy';

/// The channel method that toggles the shield. Its single argument is a
/// bool; the native side rejects anything else.
const String setSecureMethod = 'setSecure';

/// [SecureWindowGateway] over the `agenda/app_privacy` method channel.
@LazySingleton(as: SecureWindowGateway)
class SecureWindowChannel implements SecureWindowGateway {
  static const MethodChannel _channel = MethodChannel(appPrivacyChannelName);

  @override
  Future<bool> setSecure({required bool enabled}) async {
    if (defaultTargetPlatform != TargetPlatform.android &&
        defaultTargetPlatform != TargetPlatform.iOS) {
      return false;
    }
    try {
      return await _channel.invokeMethod<bool>(setSecureMethod, enabled) ??
          false;
    } on Object {
      return false;
    }
  }
}
