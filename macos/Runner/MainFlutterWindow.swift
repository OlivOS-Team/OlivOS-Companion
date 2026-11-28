import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
  private var windowChannel: FlutterMethodChannel?
  private var titleBarDark = false
  private var launchSplashActive = false

  override func awakeFromNib() {
    let flutterViewController = FlutterViewController()
    let windowFrame = self.frame
    self.contentViewController = flutterViewController
    self.setFrame(windowFrame, display: true)
    // Keep a compact, usable viewport available on desktop.
    self.minSize = NSSize(width: 480, height: 640)

    RegisterGeneratedPlugins(registry: flutterViewController)

    let channel = FlutterMethodChannel(
      name: "olivos_companion/window",
      binaryMessenger: flutterViewController.engine.binaryMessenger
    )
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "setTitleBarTheme":
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
        self?.titleBarDark = dark
        self?.applyTitleBarStyle()
        result(nil)
      case "setLaunchSplashActive":
        guard let active = call.arguments as? Bool else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "Expected a boolean",
              details: nil
            )
          )
          return
        }
        self?.launchSplashActive = active
        self?.applyTitleBarStyle()
        result(nil)
      case "getRefreshRate":
        guard let screen = self?.screen ?? NSScreen.main else {
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
      default:
        result(FlutterMethodNotImplemented)
      }
    }
    windowChannel = channel

    super.awakeFromNib()

    let info = Bundle.main.localizedInfoDictionary ?? Bundle.main.infoDictionary
    let appName =
      (info?["CFBundleDisplayName"] as? String)
      ?? (info?["CFBundleName"] as? String)
      ?? "OlivOS Companion"
    var title = appName
    if let version = Bundle.main.object(
      forInfoDictionaryKey: "CFBundleShortVersionString"
    ) as? String, !version.isEmpty {
      title += " v\(version)"
    }
    self.title = title
  }

  private func applyTitleBarStyle() {
    if launchSplashActive {
      appearance = NSAppearance(named: .darkAqua)
      backgroundColor = NSColor(
        srgbRed: 0.0,
        green: 160.0 / 255.0,
        blue: 234.0 / 255.0,
        alpha: 1.0
      )
      titlebarAppearsTransparent = true
      titlebarSeparatorStyle = .none
      return
    }

    appearance = NSAppearance(named: titleBarDark ? .darkAqua : .aqua)
    backgroundColor = .windowBackgroundColor
    titlebarAppearsTransparent = false
    titlebarSeparatorStyle = .automatic
  }
}
