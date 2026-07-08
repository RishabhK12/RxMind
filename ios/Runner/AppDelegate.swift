import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: MasterKeyModule.channel,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        switch call.method {
        case "provisionMasterKey":
          result(MasterKeyModule.provisionMasterKey())
        case "getMasterKeyAlias":
          result(MasterKeyModule.getMasterKeyAlias())
        case "isStrongBoxBacked":
          result(false)
        case "deriveDatabaseKey":
          do {
            let key = try MasterKeyModule.deriveDatabaseKey()
            result(FlutterStandardTypedData(bytes: key))
          } catch {
            result(FlutterError(
              code: "DATABASE_KEY_UNAVAILABLE",
              message: error.localizedDescription,
              details: nil
            ))
          }
        case "getSalt":
          do {
            let salt = try MasterKeyModule.getSalt()
            result(FlutterStandardTypedData(bytes: salt))
          } catch {
            result(FlutterError(code: "SALT_UNAVAILABLE", message: error.localizedDescription, details: nil))
          }
        case "wipeAll":
          do {
            try MasterKeyModule.wipeAll()
            result(true)
          } catch {
            result(FlutterError(code: "WIPE_FAILED", message: error.localizedDescription, details: nil))
          }
        default:
          result(FlutterMethodNotImplemented)
        }
      }
    }

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
