import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Timeline

struct CatEntry: TimelineEntry {
    let date: Date
    let state: CatState
}

struct CatProvider: TimelineProvider {
    func placeholder(in context: Context) -> CatEntry {
        CatEntry(date: Date(), state: CatState())
    }

    func getSnapshot(in context: Context, completion: @escaping (CatEntry) -> Void) {
        completion(CatEntry(date: Date(), state: CatStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CatEntry>) -> Void) {
        let now = Date()
        let base = CatStore.load(at: now)

        // Now, the moment the current reaction ends, then every 15 minutes for 4 hours
        var dates: [Date] = [now]
        if base.reactionUntil > now {
            dates.append(base.reactionUntil.addingTimeInterval(0.5))
        }
        for i in 1...16 {
            dates.append(now.addingTimeInterval(Double(i) * 15 * 60))
        }
        dates.sort()

        let entries = dates.map { CatEntry(date: $0, state: base.advanced(to: $0)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

// MARK: - Widget

struct CatHomeWidget: Widget {
    let kind = "CatHomeWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatProvider()) { entry in
            CatWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("\(CatInfo.name)'s Home")
        .description("Your cat lives here. Tap him to pet, the bowl to feed, the yarn to play, the lamp for bedtime.")
        .supportedFamilies([.systemSmall, .systemLarge])
        .contentMarginsDisabled()
    }
}

struct CatWidgetEntryView: View {
    @Environment(\.widgetFamily) private var family
    let entry: CatEntry

    var body: some View {
        Group {
            switch family {
            case .systemSmall:
                Scaled(SmallCatView.size) {
                    SmallCatView(state: entry.state)
                }
            default:
                Scaled(RoomView.size) {
                    RoomView(state: entry.state, date: entry.date)
                }
            }
        }
        .containerBackground(for: .widget) { Color.wall }
    }
}

// MARK: - Small widget: just the cat

struct SmallCatView: View {
    let state: CatState
    static let size = CGSize(width: 170, height: 170)

    var body: some View {
        ZStack {
            Color.wall
            Rectangle().fill(Color.floorWood)
                .frame(width: 170, height: 46)
                .position(x: 85, y: 147)
            Rectangle().fill(Color.baseboard)
                .frame(width: 170, height: 6)
                .position(x: 85, y: 124)

            Text(CatInfo.name)
                .font(.system(size: 13, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
                .position(x: 34, y: 16)
            Text("♥ \(state.hearts)")
                .font(.system(size: 11, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.90, green: 0.35, blue: 0.45))
                .position(x: 140, y: 16)

            Button(intent: PetCatIntent()) {
                CatView(state: state)
            }
            .buttonStyle(.plain)
            .position(x: 78, y: 104)

            Button(intent: FeedCatIntent()) {
                Text("🍗")
                    .font(.system(size: 17))
                    .frame(width: 36, height: 36)
                    .background(Circle().fill(Color.white.opacity(0.9)))
            }
            .buttonStyle(.plain)
            .position(x: 146, y: 144)

            if state.isSleeping {
                Color(red: 0.06, green: 0.07, blue: 0.24)
                    .opacity(0.3)
                    .allowsHitTesting(false)
            }

            if let msg = state.message {
                Bubble(text: msg, fontSize: 11)
                    .position(x: 85, y: 40)
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                    .id(msg)
            }
        }
        .frame(width: 170, height: 170)
    }
}
