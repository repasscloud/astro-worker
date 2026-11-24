import Foundation

struct MoonWidgetSnapshot: Decodable {
  let schema: Int
  let generatedAt: Date
  let validUntil: Date
  let phase: String
  let illumination: Double
  let waxing: Bool?
  let south: Bool?
  let nextPhase: String?
}

enum MoonWidgetStore {
  static let kind = "AstroWorkerMoon"
  static let url = URL(string: "astroworker://moon")!
  private static let phases: Set<String> = [
    "New Moon", "Waxing Crescent", "First Quarter", "Waxing Gibbous",
    "Full Moon", "Waning Gibbous", "Last Quarter", "Waning Crescent",
  ]

  static func decode(_ data: Data) -> [MoonWidgetSnapshot]? {
    guard data.count <= 128 * 1024 else { return nil }
    let decoder = JSONDecoder()
    let timestamps = ISO8601DateFormatter()
    timestamps.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    decoder.dateDecodingStrategy = .custom { decoder in
      let value = try decoder.singleValueContainer()
      let text = try value.decode(String.self)
      guard text.hasSuffix("Z"), let instant = timestamps.date(from: text) else {
        throw DecodingError.dataCorruptedError(in: value, debugDescription: "Invalid UTC instant")
      }
      return instant
    }
    guard let snapshots = try? decoder.decode([MoonWidgetSnapshot].self, from: data),
          snapshots.count <= 64 else { return nil }
    var previousEnd: Date?
    for snapshot in snapshots {
      let duration = snapshot.validUntil.timeIntervalSince(snapshot.generatedAt)
      guard snapshot.schema == 1,
            phases.contains(snapshot.phase),
            (0...1).contains(snapshot.illumination),
            duration > 0 && duration <= 3600.001,
            previousEnd == nil || previousEnd == snapshot.generatedAt,
            snapshot.nextPhase.map(phases.contains) ?? true else { return nil }
      previousEnd = snapshot.validUntil
    }
    if let first = snapshots.first, let last = snapshots.last,
       last.validUntil.timeIntervalSince(first.generatedAt) > 48 * 3600 + 0.001 {
      return nil
    }
    return snapshots
  }

  static var sharingEnabled: Bool {
    Bundle.main.object(forInfoDictionaryKey: "AstroWidgetEnabled") as? String == "YES"
  }

  static func load() -> [MoonWidgetSnapshot] {
    guard let file = sharedFile, let data = try? Data(contentsOf: file) else { return [] }
    return decode(data) ?? []
  }

  static func publish(_ data: Data) throws {
    guard decode(data) != nil else { throw StoreError.invalidTimeline }
    guard let file = sharedFile else { throw StoreError.groupUnavailable }
    try data.write(to: file, options: .atomic)
  }

  private static var sharedFile: URL? {
    guard sharingEnabled,
          let group = Bundle.main.object(forInfoDictionaryKey: "AstroWidgetGroup") as? String,
          let folder = FileManager.default.containerURL(
            forSecurityApplicationGroupIdentifier: group
          ) else { return nil }
    return folder.appendingPathComponent("moon-timeline.json", isDirectory: false)
  }

  enum StoreError: Error {
    case invalidTimeline
    case groupUnavailable
  }
}
