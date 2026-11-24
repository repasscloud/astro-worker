import SwiftUI
import WidgetKit

private struct MoonEntry: TimelineEntry {
  let date: Date
  let snapshot: MoonWidgetSnapshot?
}

private struct MoonProvider: TimelineProvider {
  func placeholder(in context: Context) -> MoonEntry {
    let now = Date()
    return MoonEntry(date: now, snapshot: MoonWidgetSnapshot(
      schema: 1, generatedAt: now, validUntil: now.addingTimeInterval(3600),
      phase: "Waxing Gibbous", illumination: 0.86, waxing: true, south: false,
      nextPhase: "Full Moon"
    ))
  }

  func getSnapshot(in context: Context, completion: @escaping (MoonEntry) -> Void) {
    if context.isPreview {
      completion(placeholder(in: context))
    } else {
      let now = Date()
      completion(MoonEntry(date: now, snapshot: current(at: now, in: MoonWidgetStore.load())))
    }
  }

  func getTimeline(in context: Context, completion: @escaping (Timeline<MoonEntry>) -> Void) {
    let now = Date()
    let snapshots = MoonWidgetStore.load()
    var entries = [MoonEntry(date: now, snapshot: current(at: now, in: snapshots))]
    for snapshot in snapshots where snapshot.generatedAt > now {
      entries.append(MoonEntry(date: snapshot.generatedAt, snapshot: snapshot))
    }
    if let expiry = snapshots.last?.validUntil, expiry > now {
      entries.append(MoonEntry(date: expiry, snapshot: nil))
    }
    completion(Timeline(entries: entries, policy: .never))
  }

  private func current(at now: Date, in snapshots: [MoonWidgetSnapshot]) -> MoonWidgetSnapshot? {
    snapshots.first { $0.generatedAt <= now && now < $0.validUntil }
  }
}

private struct MoonArt: View {
  let light: Double
  let right: Bool

  var body: some View {
    Canvas { context, size in
      let radius = min(size.width, size.height) / 2
      let x = size.width / 2
      let y = size.height / 2
      context.fill(Path(ellipseIn: CGRect(
        x: x - radius, y: y - radius, width: radius * 2, height: radius * 2
      )), with: .color(Color(red: 0.23, green: 0.21, blue: 0.31)))
      var illuminated = Path()
      illuminated.move(to: CGPoint(x: x, y: y - radius))
      let side = right ? 1.0 : -1.0
      for index in 0...64 {
        let angle = Double.pi * Double(index) / 64
        illuminated.addLine(to: CGPoint(
          x: x + side * radius * sin(angle), y: y - radius * cos(angle)
        ))
      }
      for index in (0...64).reversed() {
        let angle = Double.pi * Double(index) / 64
        illuminated.addLine(to: CGPoint(
          x: x + side * radius * (1 - 2 * light) * sin(angle), y: y - radius * cos(angle)
        ))
      }
      illuminated.closeSubpath()
      context.fill(illuminated, with: .color(Color(red: 1, green: 0.89, blue: 0.67)))
    }
    .aspectRatio(1, contentMode: .fit)
    .accessibilityHidden(true)
  }
}

private struct MoonWidgetView: View {
  @Environment(\.widgetFamily) private var family
  let entry: MoonEntry

  var body: some View {
    Group {
      if let moon = entry.snapshot {
        if family == .systemSmall {
          VStack(spacing: 8) {
            art(for: moon)
            Text(moon.phase).font(.headline).lineLimit(2)
          }
          .accessibilityLabel(moon.phase)
        } else {
          HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 5) {
              Text("Moon phase").font(.caption)
              Text(moon.phase).font(.headline)
              Text("\(moon.illumination.formatted(.percent.precision(.fractionLength(0)))) illuminated")
                .font(.caption)
              if let next = moon.nextPhase {
                Text("Next · \(next)").font(.caption)
              }
            }
            Spacer(minLength: 0)
            art(for: moon)
          }
        }
      } else {
        VStack(alignment: .leading, spacing: 8) {
          Text("Open Astro Worker").font(.headline)
          Text("Click to refresh Moon data").font(.caption)
        }
      }
    }
    .foregroundStyle(Color(red: 0.96, green: 0.93, blue: 0.98))
    .containerBackground(for: .widget) {
      Color(red: 0.12, green: 0.09, blue: 0.17)
    }
    .widgetURL(MoonWidgetStore.url)
  }

  private func art(for moon: MoonWidgetSnapshot) -> some View {
    MoonArt(light: moon.illumination, right: (moon.waxing ?? true) != (moon.south ?? false))
      .frame(maxWidth: 90, maxHeight: 90)
  }
}

@main
struct AstroMoonWidget: Widget {
  var body: some WidgetConfiguration {
    StaticConfiguration(kind: MoonWidgetStore.kind, provider: MoonProvider()) { entry in
      MoonWidgetView(entry: entry)
    }
    .configurationDisplayName("Astro Worker Moon")
    .description("Current Moon phase and offline lunar details.")
    .supportedFamilies([.systemSmall, .systemMedium])
  }
}
