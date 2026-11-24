import Cocoa
import FlutterMacOS
import WidgetKit
import UserNotifications

@main
class AppDelegate: FlutterAppDelegate {
  private var widgetChannel: FlutterMethodChannel?
  private var reminderChannel: FlutterMethodChannel?
  private var pendingMoonURL = false

  func attachMoonWidgetChannel(to messenger: FlutterBinaryMessenger) {
    if #available(macOS 12.0, *) {
      attachReminderChannel(to: messenger)
    }
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

  @available(macOS 12.0, *)
  private func attachReminderChannel(to messenger: FlutterBinaryMessenger) {
    let channel = FlutterMethodChannel(name: "astro_worker/reminders", binaryMessenger: messenger)
    reminderChannel = channel
    channel.setMethodCallHandler { call, result in
      switch call.method {
      case "requestPermission":
        Task { @MainActor in
          let center = UNUserNotificationCenter.current()
          result((try? await center.requestAuthorization(options: [.alert, .sound])) ?? false)
        }
      case "replace":
        guard let text = call.arguments as? String,
              let plan = try? JSONDecoder().decode(ReminderPlan.self, from: Data(text.utf8)),
              plan.events.count <= 48 else {
          result(FlutterError(code: "invalid_reminders", message: nil, details: nil))
          return
        }
        Task { @MainActor in
          do {
            try await Self.replaceReminders(plan.events)
            result(nil)
          } catch {
            result(FlutterError(code: "reminder_schedule", message: "\(error)", details: nil))
          }
        }
      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }

  private struct ReminderPlan: Decodable {
    struct Event: Decodable {
      let id: String
      let title: String
      let due: Int64
      let event: Int64

      var requestID: String { "astro-event." + id }
    }
    let events: [Event]
  }

  @available(macOS 12.0, *)
  private static func replaceReminders(_ events: [ReminderPlan.Event]) async throws {
    let center = UNUserNotificationCenter.current()
    let authorization = await center.notificationSettings().authorizationStatus
    let registered = await center.pendingNotificationRequests()
    let current = Date()
    let scheduled = authorization == .authorized || authorization == .provisional
      ? events.filter { Date(timeIntervalSince1970: Double($0.due) / 1000) > current }
      : []
    let expected = Set(scheduled.map(\.requestID))
    let obsolete = registered.map(\.identifier).filter {
      $0.hasPrefix("astro-event.") && !expected.contains($0)
    }
    center.removePendingNotificationRequests(withIdentifiers: obsolete)
    var calendar = Calendar(identifier: .gregorian)
    calendar.timeZone = TimeZone(secondsFromGMT: 0)!
    let existing = Dictionary(uniqueKeysWithValues: registered.map { ($0.identifier, $0) })
    for event in scheduled {
      let when = Date(timeIntervalSince1970: Double(event.due) / 1000)
      var components = calendar.dateComponents([.year, .month, .day, .hour, .minute, .second], from: when)
      components.timeZone = calendar.timeZone
      if let prior = existing[event.requestID]?.trigger as? UNCalendarNotificationTrigger,
         prior.dateComponents == components { continue }
      let content = UNMutableNotificationContent()
      content.title = event.title
      content.body = event.event == event.due ? "Astronomy event" : "Upcoming astronomy event"
      content.sound = .default
      try await center.add(UNNotificationRequest(
        identifier: event.requestID,
        content: content,
        trigger: UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
      ))
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
