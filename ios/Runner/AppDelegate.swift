import Flutter
import UIKit
import UserNotifications
import workmanager_apple

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  private var documentExporter: DocumentExporter?
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self
    WorkmanagerPlugin.setPluginRegistrantCallback { registry in
      GeneratedPluginRegistrant.register(with: registry)
    }
    WorkmanagerPlugin.registerLaunchHandlers()
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    if let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "UnioDocumentExporter") {
      documentExporter = DocumentExporter(messenger: registrar.messenger())
    }
  }
}

private final class DocumentExporter: NSObject, UIDocumentPickerDelegate {
  private let channel: FlutterMethodChannel
  private var pendingResult: FlutterResult?
  private var temporaryDirectory: URL?

  init(messenger: FlutterBinaryMessenger) {
    channel = FlutterMethodChannel(name: "unio/document_export", binaryMessenger: messenger)
    super.init()
    channel.setMethodCallHandler { [weak self] call, result in
      guard let self = self else { result(false); return }
      guard call.method == "saveDocument" else { result(FlutterMethodNotImplemented); return }
      self.save(call.arguments, result: result)
    }
  }

  private func save(_ arguments: Any?, result: @escaping FlutterResult) {
    guard pendingResult == nil else {
      result(FlutterError(code: "busy", message: "A save dialog is already open", details: nil))
      return
    }
    guard let args = arguments as? [String: Any],
          let name = args["name"] as? String, !name.isEmpty,
          !name.contains("/"), !name.contains("\\"),
          let bytes = args["bytes"] as? FlutterStandardTypedData else {
      result(FlutterError(code: "invalid", message: "Invalid document", details: nil))
      return
    }
    guard var presenter = UIApplication.shared.connectedScenes
      .compactMap({ $0 as? UIWindowScene })
      .filter({ $0.activationState == .foregroundActive })
      .flatMap({ $0.windows }).first(where: { $0.isKeyWindow })?.rootViewController else {
      result(FlutterError(code: "unavailable", message: "No active window", details: nil))
      return
    }
    while let presented = presenter.presentedViewController { presenter = presented }
    do {
      let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
      try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
      temporaryDirectory = directory
      let file = directory.appendingPathComponent(name)
      try bytes.data.write(to: file, options: .atomic)
      let picker: UIDocumentPickerViewController
      if #available(iOS 14.0, *) {
        picker = UIDocumentPickerViewController(forExporting: [file], asCopy: true)
      } else {
        picker = UIDocumentPickerViewController(url: file, in: .exportToService)
      }
      picker.delegate = self
      picker.isModalInPresentation = true
      pendingResult = result
      presenter.present(picker, animated: true)
    } catch {
      cleanUp()
      result(FlutterError(code: "write_failed", message: "Could not save document", details: nil))
    }
  }

  func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
    finish(!urls.isEmpty)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) { finish(false) }

  private func finish(_ saved: Bool) {
    let result = pendingResult
    pendingResult = nil
    cleanUp()
    result?(saved)
  }

  private func cleanUp() {
    if let directory = temporaryDirectory { try? FileManager.default.removeItem(at: directory) }
    temporaryDirectory = nil
  }
}
