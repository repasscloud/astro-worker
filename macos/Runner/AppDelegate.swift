import Cocoa
import FlutterMacOS
import WidgetKit

@main
class AppDelegate: FlutterAppDelegate {
  private var widgetChannel: FlutterMethodChannel?
  private var pendingMoonURL = false

  func attachMoonWidgetChannel(to messenger: FlutterBinaryMessenger) {
    guard #available(macOS 14.0, *) else { return }
    let channel = FlutterMethodChannel(name: "astro_worker/moon_widget", binaryMessenger: messenger)
    widgetChannel = channel
    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "consumeOpenMoon":
        let open = self?.pendingMoonURL ?? false
        self?.pendingMoonURL = false
        result(open ? "phase" : nil)
      case "publish":
        guard MoonWidgetStore.sharingEnabled else {
          result(nil)
          return
        }
        do {
          guard let text = call.arguments as? String else {
            throw MoonWidgetStore.StoreError.invalidTimeline
          }
          try MoonWidgetStore.publish(Data(text.utf8))
          WidgetCenter.shared.reloadTimelines(ofKind: MoonWidgetStore.kind)
          result(nil)
        } catch {
          result(FlutterError(code: "moon_widget_publish", message: "\(error)", details: nil))
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  override func application(_ application: NSApplication, open urls: [URL]) {
    guard urls.contains(MoonWidgetStore.url) else {
      super.application(application, open: urls)
      return
    }
    pendingMoonURL = true
    widgetChannel?.invokeMethod("openMoon", arguments: "phase") { [weak self] response in
      if let response = response, response as AnyObject === FlutterMethodNotImplemented { return }
      self?.pendingMoonURL = false
    }
  }

  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
