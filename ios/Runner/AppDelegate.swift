import Flutter
import UIKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private static let channelName = "com.smartworkspace.app/native"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    let launched = super.application(application, didFinishLaunchingWithOptions: launchOptions)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: AppDelegate.channelName,
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { [weak controller] call, result in
        guard let controller = controller else {
          result(FlutterError(code: "NO_CONTROLLER", message: "Root view controller unavailable", details: nil))
          return
        }
        AppDelegate.handle(call, on: controller, result: result)
      }
    }
    return launched
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
  }

  private static func handle(
    _ call: FlutterMethodCall,
    on controller: FlutterViewController,
    result: @escaping FlutterResult
  ) {
    switch call.method {
    case "pickDate":
      let args = call.arguments as? [String: Any]
      presentDatePicker(on: controller, initialDateIso: args?["initialDate"] as? String, result: result)
    case "showNativeOptionsSheet":
      presentOptionsSheet(on: controller, result: result)
    case "getDeviceInfo":
      result(deviceInfo())
    default:
      result(FlutterMethodNotImplemented)
    }
  }

  private static func presentDatePicker(
    on controller: FlutterViewController,
    initialDateIso: String?,
    result: @escaping FlutterResult
  ) {
    let picker = UIDatePicker()
    picker.datePickerMode = .date
    picker.preferredDatePickerStyle = .inline
    if let initialDateIso = initialDateIso, let date = isoDateFormatter.date(from: initialDateIso) {
      picker.date = date
    }

    let sheet = UIViewController()
    sheet.modalPresentationStyle = .pageSheet
    sheet.sheetPresentationController?.detents = [.medium()]

    var answered = false
    func respond(_ value: String?) {
      if !answered {
        answered = true
        result(value)
      }
      sheet.dismiss(animated: true)
    }

    let toolbar = UIToolbar()
    toolbar.translatesAutoresizingMaskIntoConstraints = false
    toolbar.items = [
      UIBarButtonItem(title: "Cancel", primaryAction: UIAction { _ in respond(nil) }),
      UIBarButtonItem(systemItem: .flexibleSpace),
      UIBarButtonItem(
        title: "Done",
        primaryAction: UIAction { _ in respond(isoDateFormatter.string(from: picker.date)) }
      ),
    ]

    picker.translatesAutoresizingMaskIntoConstraints = false
    sheet.view.backgroundColor = .systemBackground
    sheet.view.addSubview(toolbar)
    sheet.view.addSubview(picker)
    NSLayoutConstraint.activate([
      toolbar.topAnchor.constraint(equalTo: sheet.view.safeAreaLayoutGuide.topAnchor),
      toolbar.leadingAnchor.constraint(equalTo: sheet.view.leadingAnchor),
      toolbar.trailingAnchor.constraint(equalTo: sheet.view.trailingAnchor),
      picker.topAnchor.constraint(equalTo: toolbar.bottomAnchor, constant: 8),
      picker.leadingAnchor.constraint(equalTo: sheet.view.leadingAnchor, constant: 16),
      picker.trailingAnchor.constraint(equalTo: sheet.view.trailingAnchor, constant: -16),
    ])
    sheet.presentationController?.delegate = NativeSheetDismissForwarder.shared
    NativeSheetDismissForwarder.shared.onDismiss = { respond(nil) }

    controller.present(sheet, animated: true)
  }

  private static func presentOptionsSheet(on controller: FlutterViewController, result: @escaping FlutterResult) {
    var answered = false
    func respond(_ value: String?) {
      if !answered {
        answered = true
        result(value)
      }
    }

    let alert = UIAlertController(title: "Add image", message: nil, preferredStyle: .actionSheet)
    alert.addAction(UIAlertAction(title: "Camera", style: .default) { _ in respond("camera") })
    alert.addAction(UIAlertAction(title: "Gallery", style: .default) { _ in respond("gallery") })
    alert.addAction(UIAlertAction(title: "File Picker", style: .default) { _ in respond("file") })
    alert.addAction(UIAlertAction(title: "Cancel", style: .cancel) { _ in respond(nil) })

    // iPad requires an anchor for action sheets or it crashes at present time.
    if let popover = alert.popoverPresentationController {
      popover.sourceView = controller.view
      popover.sourceRect = CGRect(x: controller.view.bounds.midX, y: controller.view.bounds.maxY, width: 0, height: 0)
    }

    controller.present(alert, animated: true)
  }

  private static func deviceInfo() -> [String: Any] {
    let device = UIDevice.current
    device.isBatteryMonitoringEnabled = true
    let level = device.batteryLevel
    let batteryPercent = level < 0 ? -1 : Int(level * 100)

    return [
      "model": device.model,
      "osVersion": device.systemVersion,
      "batteryPercent": batteryPercent,
    ]
  }

  private static let isoDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd"
    formatter.calendar = Calendar(identifier: .gregorian)
    formatter.timeZone = TimeZone(identifier: "UTC")
    return formatter
  }()
}

/// UISheetPresentationController needs a delegate object to catch swipe-to-dismiss;
/// a single shared forwarder avoids a bespoke NSObject subclass per presentation.
private class NativeSheetDismissForwarder: NSObject, UIAdaptivePresentationControllerDelegate {
  static let shared = NativeSheetDismissForwarder()
  var onDismiss: (() -> Void)?

  func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
    onDismiss?()
  }
}
