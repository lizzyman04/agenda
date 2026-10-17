import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    excludeUserDataFromBackup()
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // Keeps the Isar database and the plaintext safety backups out of iCloud and
  // iTunes backup (CR-01, D-13). Excluding a directory excludes everything
  // beneath it. Failures are ignored so launch is never blocked.
  private func excludeUserDataFromBackup() {
    guard var documents = FileManager.default.urls(
      for: .documentDirectory, in: .userDomainMask).first else { return }
    var backups = documents.appendingPathComponent("backups", isDirectory: true)
    try? FileManager.default.createDirectory(
      at: backups, withIntermediateDirectories: true)
    var values = URLResourceValues()
    values.isExcludedFromBackup = true
    try? documents.setResourceValues(values)
    try? backups.setResourceValues(values)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}
