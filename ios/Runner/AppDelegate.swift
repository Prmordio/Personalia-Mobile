import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    // Registra o delegate ANTES do super para que flutter_local_notifications
    // consiga exibir notificações locais com o app em primeiro plano (iOS 10+).
    if #available(iOS 10.0, *) {
      UNUserNotificationCenter.current().delegate = self
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)
    let registrar = engineBridge.pluginRegistry.registrar(forPlugin: "WorkoutLive")!
    let channel = FlutterMethodChannel(name: "personalia/workout_live", binaryMessenger: registrar.messenger())
    channel.setMethodCallHandler { call, result in
      guard #available(iOS 17.0, *) else { result(FlutterMethodNotImplemented); return }
      Task { @MainActor in
        do {
          let args = call.arguments as? [String: Any] ?? [:]
          let state: WorkoutSnapshot?
          switch call.method {
          case "read": state = WorkoutActivityStore.read()
          case "localize":
            guard let json = args["json"] as? String else { throw NSError(domain: "WorkoutLive", code: 1) }
            state = try await WorkoutActivityStore.localize(json)
          case "weight":
            guard let id = args["id"] as? String, let name = args["name"] as? String,
                  let value = args["value"] as? String else { throw NSError(domain: "WorkoutLive", code: 2) }
            state = try await WorkoutActivityStore.weight(id: id, name: name, value: value)
          case "prepare":
            guard let json = args["json"] as? String else { throw NSError(domain: "WorkoutLive", code: 1) }
            state = try await WorkoutActivityStore.prepare(json)
          case "action":
            guard let action = args["action"] as? String, let id = args["id"] as? String,
                  let revision = args["revision"] as? Int else { throw NSError(domain: "WorkoutLive", code: 2) }
            if action == "rest" {
              _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
            }
            state = try await WorkoutActivityStore.action(action, id: id, revision: revision)
          case "end": await WorkoutActivityStore.end(); state = nil
          default: result(FlutterMethodNotImplemented); return
          }
          result(try WorkoutActivityStore.json(state))
        } catch { result(FlutterError(code: "workout_live", message: error.localizedDescription, details: nil)) }
      }
    }
  }
}
