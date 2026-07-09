import Contacts
import ContactsUI
import Flutter
import UIKit

class ContactPickerModule: NSObject, CNContactPickerDelegate {
  static let channel = "rxmind/contacts"

  private var pendingResult: FlutterResult?
  private weak var viewController: UIViewController?

  func attach(to controller: UIViewController) {
    viewController = controller
  }

  func pickSingleContact(result: @escaping FlutterResult) {
    pendingResult = result
    guard let vc = viewController else {
      result(FlutterError(code: "NO_VC", message: "No view controller", details: nil))
      return
    }
    let picker = CNContactPickerViewController()
    picker.delegate = self
    picker.predicateForEnablingContact = NSPredicate(format: "phoneNumbers.@count > 0")
    vc.present(picker, animated: true)
  }

  func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
    let name = CNContactFormatter.string(from: contact, style: .fullName) ?? ""
    let phone = contact.phoneNumbers.first?.value.stringValue ?? ""
    pendingResult?(["name": name, "phone": phone])
    pendingResult = nil
  }

  func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
    pendingResult?(nil)
    pendingResult = nil
  }
}
