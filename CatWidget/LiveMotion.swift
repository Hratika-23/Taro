import SwiftUI
import ClockHandRotationKit

// MARK: - Live motion on the home screen
//
// Widgets are frozen snapshots, except clock hands, which iOS keeps turning.
// ClockHandRotationKit borrows that rotation. FrameLoop turns it into a flip-book:
// all frames are stacked, each masked by one slice of a huge, slowly spinning
// wheel, so exactly one frame shows at a time and the next slides in as it turns.

struct FrameLoop<Content: View>: View {
    let count: Int
    let period: TimeInterval
    let size: CGSize
    let content: (Int) -> Content

    init(count: Int, period: TimeInterval, size: CGSize, @ViewBuilder content: @escaping (Int) -> Content) {
        self.count = count; self.period = period; self.size = size; self.content = content
    }

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                content(i)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .mask { WheelSliceMask(index: i, count: count, period: period, size: size) }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

private struct WheelSliceMask: View {
    let index: Int, count: Int
    let period: TimeInterval
    let size: CGSize

    var body: some View {
        let side = max(size.width, size.height)
        let radius = side * max(8, CGFloat(count) * 0.5)
        let slice = 360.0 / Double(count)
        let start = -90.0 - Double(index + 1) * slice
        let end = -90.0 - Double(index) * slice + 0.4
        Wedge(startDegrees: start, endDegrees: end)
            .fill(Color.black)
            .frame(width: radius * 2, height: radius * 2)
            .clockHandRotationEffect(period: .custom(period))
            .offset(y: radius - side)
    }
}

struct Wedge: Shape {
    var startDegrees: Double
    var endDegrees: Double
    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY), r = rect.width / 2
        var p = Path()
        p.move(to: c)
        for k in 0...12 {
            let deg = startDegrees + (endDegrees - startDegrees) * Double(k) / 12
            let a = CGFloat(deg) * .pi / 180
            p.addLine(to: CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)))
        }
        p.closeSubpath()
        return p
    }
}

enum HandKind { case hour, minute, second }

extension View {
    /// Spins forever, once every `period` seconds.
    func spinForever(period: TimeInterval, anchor: UnitPoint = .center) -> some View {
        clockHandRotationEffect(period: .custom(period), anchor: anchor)
    }
    /// Turns like a real clock hand (pointing up at 12).
    func clockHand(_ kind: HandKind) -> some View {
        switch kind {
        case .hour: return AnyView(clockHandRotationEffect(period: .hourHand))
        case .minute: return AnyView(clockHandRotationEffect(period: .minuteHand))
        case .second: return AnyView(clockHandRotationEffect(period: .secondHand))
        }
    }
}
