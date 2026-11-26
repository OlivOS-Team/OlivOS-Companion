import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var windowChannel: FlutterMethodChannel?

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // Keep a phone-portrait viewport available on desktop.
    self.minSize = NSSize(width: 360, height: 640)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "olivos_companion/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      guard call.method == "setTitleBarTheme" else {
        result(FlutterMethodNotImplemented)
        return
      }
      guard let dark = call.arguments as? Bool else {
        result(
          FlutterError(
            code: "invalid_arguments",
            message: "Expected a boolean",
            details: nil
          )
        )
        return
      }
      self?.appearance = NSAppearance(named: dark ? .darkAqua : .aqua)
      result(nil)
    }
    windowChannel = channel

    super.awakeFromNib()

    if let version = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String, !version.isEmpty {
      self.title = "OlivOS Companion v\(version)"
    }
  }
}
