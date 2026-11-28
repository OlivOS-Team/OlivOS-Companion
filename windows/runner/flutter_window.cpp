#include "flutter_window.h"

#include <flutter/standard_method_codec.h>

#include <optional>
#include <variant>

#include "flutter/generated_plugin_registrant.h"

namespace {

constexpr int kFullscreenHotkeyId = 1;

}  // namespace

FlutterWindow::FlutterWindow(const flutter::DartProject& project)
    : project_(project) {}

FlutterWindow::~FlutterWindow() {}

bool FlutterWindow::OnCreate() {
  if (!Win32Window::OnCreate()) {
    return false;
  }

  RECT frame = GetClientArea();

  // The size here must match the window dimensions to avoid unnecessary surface
  // creation / destruction in the startup path.
  flutter_controller_ = std::make_unique<flutter::FlutterViewController>(
      frame.right - frame.left, frame.bottom - frame.top, project_);
  // Ensure that basic setup of the controller was successful.
  if (!flutter_controller_->engine() || !flutter_controller_->view()) {
    return false;
  }
  RegisterPlugins(flutter_controller_->engine());
  SetChildContent(flutter_controller_->view()->GetNativeWindow());

  window_channel_ =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          flutter_controller_->engine()->messenger(),
          "olivos_companion/window",
          &flutter::StandardMethodCodec::GetInstance());
  window_channel_->SetMethodCallHandler(
      [this](const flutter::MethodCall<flutter::EncodableValue>& call,
             std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>>
                 result) {
        if (call.method_name() == "setTitleBarTheme") {
          const auto* dark_mode = std::get_if<bool>(call.arguments());
          if (dark_mode == nullptr) {
            result->Error("invalid_arguments", "Expected a boolean");
            return;
          }
          SetThemeOverride(*dark_mode);
          result->Success();
          return;
        }
        if (call.method_name() == "setLaunchSplashActive") {
          const auto* active = std::get_if<bool>(call.arguments());
          if (active == nullptr) {
            result->Error("invalid_arguments", "Expected a boolean");
            return;
          }
          SetLaunchSplashActive(*active);
          result->Success();
          return;
        }
        if (call.method_name() == "getRefreshRate") {
          HMONITOR monitor =
              MonitorFromWindow(GetHandle(), MONITOR_DEFAULTTONEAREST);
          MONITORINFOEXW monitor_info{};
          monitor_info.cbSize = sizeof(MONITORINFOEXW);
          if (monitor == nullptr ||
              !GetMonitorInfoW(monitor, &monitor_info)) {
            result->Error("unavailable", "Could not read monitor info");
            return;
          }

          DEVMODEW mode{};
          mode.dmSize = sizeof(DEVMODEW);
          if (!EnumDisplaySettingsW(monitor_info.szDevice,
                                    ENUM_CURRENT_SETTINGS, &mode)) {
            result->Error("unavailable", "Could not read display settings");
            return;
          }
          if (mode.dmDisplayFrequency <= 1) {
            result->Error("unavailable", "Display refresh rate is unknown");
            return;
          }
          result->Success(flutter::EncodableValue(
              static_cast<int32_t>(mode.dmDisplayFrequency)));
          return;
        }
        result->NotImplemented();
      });

  flutter_controller_->engine()->SetNextFrameCallback([&]() {
    this->Show();
  });

  // Flutter can complete the first frame before the "show window" callback is
  // registered. The following call ensures a frame is pending to ensure the
  // window is shown. It is a no-op if the first frame hasn't completed yet.
  flutter_controller_->ForceRedraw();

  return true;
}

void FlutterWindow::OnDestroy() {
  SetFullscreenHotkey(false);
  window_channel_ = nullptr;
  if (flutter_controller_) {
    flutter_controller_ = nullptr;
  }

  Win32Window::OnDestroy();
}

LRESULT
FlutterWindow::MessageHandler(HWND hwnd, UINT const message,
                              WPARAM const wparam,
                              LPARAM const lparam) noexcept {
  if (message == WM_HOTKEY && wparam == kFullscreenHotkeyId) {
    ToggleBorderlessFullscreen();
    return 0;
  }

  // Fallback when RegisterHotKey is unavailable because another process owns
  // the hotkey.
  if (message == WM_KEYDOWN && wparam == VK_F11) {
    ToggleBorderlessFullscreen();
    return 0;
  }

  if (message == WM_ACTIVATE) {
    SetFullscreenHotkey(LOWORD(wparam) != WA_INACTIVE);
  }

  // Give Flutter, including plugins, an opportunity to handle window messages.
  if (flutter_controller_) {
    std::optional<LRESULT> result =
        flutter_controller_->HandleTopLevelWindowProc(hwnd, message, wparam,
                                                      lparam);
    if (result) {
      return *result;
    }
  }

  switch (message) {
    case WM_FONTCHANGE:
      flutter_controller_->engine()->ReloadSystemFonts();
      break;
  }

  return Win32Window::MessageHandler(hwnd, message, wparam, lparam);
}

void FlutterWindow::SetFullscreenHotkey(bool enabled) {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) return;

  if (enabled) {
    if (!fullscreen_hotkey_registered_) {
      fullscreen_hotkey_registered_ =
          RegisterHotKey(hwnd, kFullscreenHotkeyId, MOD_NOREPEAT, VK_F11) !=
          FALSE;
    }
    return;
  }

  if (fullscreen_hotkey_registered_) {
    UnregisterHotKey(hwnd, kFullscreenHotkeyId);
    fullscreen_hotkey_registered_ = false;
  }
}

void FlutterWindow::ToggleBorderlessFullscreen() {
  HWND hwnd = GetHandle();
  if (hwnd == nullptr) return;

  if (!is_borderless_fullscreen_) {
    saved_window_placement_.length = sizeof(saved_window_placement_);
    if (!GetWindowPlacement(hwnd, &saved_window_placement_)) return;

    HMONITOR monitor = MonitorFromWindow(hwnd, MONITOR_DEFAULTTONEAREST);
    MONITORINFO monitor_info{};
    monitor_info.cbSize = sizeof(monitor_info);
    if (monitor == nullptr || !GetMonitorInfo(monitor, &monitor_info)) {
      return;
    }

    saved_window_style_ = GetWindowLongPtr(hwnd, GWL_STYLE);
    saved_window_ex_style_ = GetWindowLongPtr(hwnd, GWL_EXSTYLE);

    if (IsZoomed(hwnd)) {
      ShowWindow(hwnd, SW_RESTORE);
    }

    LONG_PTR style = saved_window_style_;
    style &= ~(WS_CAPTION | WS_THICKFRAME | WS_MINIMIZEBOX | WS_MAXIMIZEBOX |
               WS_SYSMENU);
    style |= WS_POPUP;
    SetWindowLongPtr(hwnd, GWL_STYLE, style);

    const RECT& monitor_rect = monitor_info.rcMonitor;
    SetWindowPos(hwnd, HWND_TOP, monitor_rect.left, monitor_rect.top,
                 monitor_rect.right - monitor_rect.left,
                 monitor_rect.bottom - monitor_rect.top,
                 SWP_FRAMECHANGED | SWP_SHOWWINDOW | SWP_NOOWNERZORDER);
    is_borderless_fullscreen_ = true;
    return;
  }

  SetWindowLongPtr(hwnd, GWL_STYLE, saved_window_style_);
  SetWindowLongPtr(hwnd, GWL_EXSTYLE, saved_window_ex_style_);
  SetWindowPos(hwnd, nullptr, 0, 0, 0, 0,
               SWP_NOMOVE | SWP_NOSIZE | SWP_NOACTIVATE | SWP_FRAMECHANGED);
  SetWindowPlacement(hwnd, &saved_window_placement_);
  is_borderless_fullscreen_ = false;
}
