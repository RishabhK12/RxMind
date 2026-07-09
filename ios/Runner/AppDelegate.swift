import Flutter
import UIKit
import BackgroundTasks

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let contactPicker = ContactPickerModule()
  private let reminderSyncTaskId = "org.rxmind.app.reminder-sync"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)

  if let controller = window?.rootViewController as? FlutterViewController {
      contactPicker.attach(to: controller)

      let contactsChannel = FlutterMethodChannel(
        name: ContactPickerModule.channel,
        binaryMessenger: controller.binaryMessenger
      )
      contactsChannel.setMethodCallHandler { [weak self] call, result in
        guard let self = self else { return }
        switch call.method {
        case "pickSingleContact":
          self.contactPicker.pickSingleContact(result: result)
        default:
          result(FlutterMethodNotImplemented)
        }
      }

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

    BGTaskScheduler.shared.register(
      forTaskWithIdentifier: reminderSyncTaskId,
      using: nil
    ) { task in
      self.handleReminderSync(task: task as! BGAppRefreshTask)
    }

    scheduleReminderSync()

    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  private func scheduleReminderSync() {
    let request = BGAppRefreshTaskRequest(identifier: reminderSyncTaskId)
    request.earliestBeginDate = Date(timeIntervalSinceNow: 12 * 60 * 60)
    try? BGTaskScheduler.shared.submit(request)
  }

  private func handleReminderSync(task: BGAppRefreshTask) {
    scheduleReminderSync()
    task.expirationHandler = {}
    // Reschedule runs on next Dart foreground resume when SQLCipher is available.
    UserDefaults.standard.set(true, forKey: "rxmind_pending_reminder_sync")
    task.setTaskCompleted(success: true)
  }
}
