import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var windowChannel: FlutterMethodChannel?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "olivos_companion/window",
      binaryMessenger: engineBridge.applicationRegistrar.messenger()
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "getRefreshRate" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let screen = self?.activeScreen() else {
        result(
          FlutterError(
            code: "unavailable",
            message: "Could not find active screen",
            details: nil
          )
        )
        return
      }
      result(screen.maximumFramesPerSecond)
    }
    windowChannel = channel
  }

  private func activeScreen() -> UIScreen? {
    let scenes = UIApplication.shared.connectedScenes.compactMap {
      $0 as? UIWindowScene
    }
    if let window = scenes.flatMap({ $0.windows }).first(where: { $0.isKeyWindow }) {
      return window.screen
    }
    return scenes.first?.screen
  }
}
