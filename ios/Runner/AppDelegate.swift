import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    if let key = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String,
       !key.isEmpty {
      GMSServices.provideAPIKey(key)
    }
    AppSwitcherCover.shared.start()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }
}

/// Covers the app with a plain screen while it is not active, so the iOS app
/// switcher snapshot does not show My Health or other personal details.
///
/// This listens for scene notifications instead of overriding the scene
/// delegate, so Flutter still gets every lifecycle callback it needs.
final class AppSwitcherCover {
  static let shared = AppSwitcherCover()

  private var covers: [ObjectIdentifier: UIView] = [:]
  private var started = false

  func start() {
    guard !started else { return }
    started = true
    let center = NotificationCenter.default
    center.addObserver(
      self, selector: #selector(sceneWillDeactivate(_:)),
      name: UIScene.willDeactivateNotification, object: nil)
    center.addObserver(
      self, selector: #selector(sceneDidActivate(_:)),
      name: UIScene.didActivateNotification, object: nil)
  }

  @objc private func sceneWillDeactivate(_ note: Notification) {
    guard let scene = note.object as? UIWindowScene,
          let window = scene.windows.first(where: { $0.isKeyWindow }) ?? scene.windows.first
    else { return }
    let id = ObjectIdentifier(scene)
    guard covers[id] == nil else { return }
    let cover = UIView(frame: window.bounds)
    cover.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    cover.backgroundColor = .systemBackground
    cover.accessibilityElementsHidden = true
    window.addSubview(cover)
    covers[id] = cover
  }

  @objc private func sceneDidActivate(_ note: Notification) {
    guard let scene = note.object as? UIScene else { return }
    covers.removeValue(forKey: ObjectIdentifier(scene))?.removeFromSuperview()
  }
}
