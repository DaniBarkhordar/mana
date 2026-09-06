import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    // The local database holds body-composition data and must not ride along
    // in an iCloud backup. Dart asks for the flag right after the file is
    // created (core/platform/backup_exclusion.dart).
    let channel = FlutterMethodChannel(
      name: "com.mananu/files",
      binaryMessenger: engineBridge.applicationBinaryMessenger
    )
    channel.setMethodCallHandler { call, result in
      guard call.method == "excludeFromBackup",
            let args = call.arguments as? [String: Any],
            let path = args["path"] as? String
      else {
        result(FlutterMethodNotImplemented)
        return
      }
      var url = URL(fileURLWithPath: path)
      guard FileManager.default.fileExists(atPath: path) else {
        result(false)
        return
      }
      do {
        var values = URLResourceValues()
        values.isExcludedFromBackup = true
        try url.setResourceValues(values)
        result(true)
      } catch {
        result(false)
      }
    }
  }
}
