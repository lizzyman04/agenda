package com.omeu.space.agenda

import android.content.ActivityNotFoundException
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import android.view.WindowManager
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

/**
 * Main activity for AGENDA.
 *
 * Extends FlutterFragmentActivity (not FlutterActivity) because local_auth
 * requires a FragmentActivity context for biometric authentication (DATA-06).
 * Changing this after Phase 5 biometric code is written would require retesting
 * all fragment-dependent plugins. Do not revert to FlutterActivity.
 *
 * See: pub.dev/packages/local_auth README — "Android integration"
 * See: AGENDA CONTEXT.md D-19
 */
class MainActivity : FlutterFragmentActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "agenda/system_settings")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "openNotificationSettings" -> result.success(openNotificationSettings())
                    else -> result.notImplemented()
                }
            }
        // Native privacy shield (D-04): FLAG_SECURE blanks screenshots, screen
        // recording and the Recents thumbnail. Only a Boolean argument is
        // accepted; anything else is rejected, never interpreted.
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "agenda/app_privacy")
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "setSecure" -> {
                        val secure = call.arguments as? Boolean
                        if (secure == null) {
                            result.error("bad_args", null, null)
                        } else {
                            if (secure) {
                                window.addFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            } else {
                                window.clearFlags(WindowManager.LayoutParams.FLAG_SECURE)
                            }
                            result.success(true)
                        }
                    }
                    else -> result.notImplemented()
                }
            }
    }

    // Opens this app's notification settings (Android 8+) or, failing that, its
    // app details page. Fixed intents only: nothing from Dart reaches them.
    private fun openNotificationSettings(): Boolean {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            try {
                val intent = Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS)
                    .putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                startActivity(intent)
                return true
            } catch (e: ActivityNotFoundException) {
                // Fall through to the app details page.
            }
        }
        return try {
            val intent = Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS)
                .setData(Uri.fromParts("package", packageName, null))
            startActivity(intent)
            true
        } catch (e: ActivityNotFoundException) {
            false
        }
    }
}
