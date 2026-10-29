import Flutter
import UIKit
import flutter_local_notifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Allows notification action handlers to run in a background isolate.
    FlutterLocalNotificationsPlugin.setPluginRegistrantCallback { (registry) in
      GeneratedPluginRegistrant.register(with: registry)
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "NudgeAppIcon") {
      registerAppIconChannel(registrar.messenger())
    }
  }

  // Palette-matched home-screen icon (lib/services/app_icon_service.dart).
  // The argument is an alternate icon name, or nil for the primary icon.
  private func registerAppIconChannel(_ messenger: FlutterBinaryMessenger) {
    FlutterMethodChannel(name: "nudge/app_icon", binaryMessenger: messenger)
      .setMethodCallHandler { call, result in
        guard call.method == "setIcon" else {
          result(FlutterMethodNotImplemented)
          return
        }
        let name = call.arguments as? String
        let app = UIApplication.shared
        // iOS shows an alert on every change, so only call it for a real one.
        guard app.supportsAlternateIcons, app.alternateIconName != name else {
          result(false)
          return
        }
        app.setAlternateIconName(name) { error in result(error == nil) }
      }
  }
}
