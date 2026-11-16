import Flutter
import UIKit

/// Native privacy shield state (D-04). Set by the "agenda/app_privacy"
/// channel in AppDelegate when a PIN is enabled or disabled, and at every
/// launch with a PIN configured.
enum PrivacyShield {
  static var enabled = false
}

class SceneDelegate: FlutterSceneDelegate {
  // Opaque view that hides the app's content from the App Switcher snapshot.
  private var cover: UIView?

  // UIKit takes the App Switcher snapshot shortly after
  // sceneDidEnterBackground returns, and Flutter may not have painted its
  // privacy overlay by then. sceneWillResignActive is not always called, so
  // the cover goes up in both (showCover is idempotent).
  override func sceneWillResignActive(_ scene: UIScene) {
    super.sceneWillResignActive(scene)
    showCover()
  }

  override func sceneDidEnterBackground(_ scene: UIScene) {
    super.sceneDidEnterBackground(scene)
    showCover()
  }

  override func sceneDidBecomeActive(_ scene: UIScene) {
    super.sceneDidBecomeActive(scene)
    cover?.removeFromSuperview()
    cover = nil
  }

  private func showCover() {
    guard PrivacyShield.enabled, cover == nil, let window = window else { return }
    let view = UIView(frame: window.bounds)
    view.backgroundColor = .systemBackground
    view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    window.addSubview(view)
    cover = view
  }
}
