import SwiftUI
import WidgetKit

struct CatEntry: TimelineEntry {
    let date: Date
    let state: CatState
}

struct CatProvider: TimelineProvider {
    func placeholder(in context: Context) -> CatEntry { CatEntry(date: Date(), state: CatState()) }

    func getSnapshot(in context: Context, completion: @escaping (CatEntry) -> Void) {
        completion(CatEntry(date: Date(), state: CatStore.load()))
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<CatEntry>) -> Void) {
        let now = Date()
        let base = CatStore.load(at: now)
        var dates: [Date] = [now]
        if base.reactionUntil > now { dates.append(base.reactionUntil.addingTimeInterval(0.5)) }
        if base.activityUntil > now { dates.append(base.activityUntil.addingTimeInterval(0.5)) }
        // Taro changes what he's doing every 10 minutes
        let slotStart = floor(now.timeIntervalSince1970 / 600) * 600
        for i in 1...24 { dates.append(Date(timeIntervalSince1970: slotStart + Double(i) * 600 + 1)) }
        dates.sort()
        let entries = dates.map { CatEntry(date: $0, state: base.advanced(to: $0)) }
        completion(Timeline(entries: entries, policy: .atEnd))
    }
}

struct CatHomeWidget: Widget {
    let kind = "TaroRoomWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: CatProvider()) { entry in
            CatWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("\(CatInfo.name)'s Room")
        .description("Tap Taro to pet him, the bowls to feed him, the yarn or pom-pom to play, the window for birds, the bed for a nap.")
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
                Scaled(SmallCatView.size) { SmallCatView(state: entry.state, date: entry.date) }
            default:
                Scaled(RoomView.size) { RoomView(state: entry.state, date: entry.date) }
            }
        }
        .containerBackground(for: .widget) { Pal.paper }
    }
}
