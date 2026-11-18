import SwiftUI
import ClockHandRotationKit

// MARK: - Live motion on the home screen
//
// Widgets are frozen snapshots, except for clock hands, which iOS keeps
// turning by itself. ClockHandRotationKit lets us borrow that rotation.
//
// FrameLoop turns that rotation into a flip-book:
// every frame of an animation is stacked on top of each other, and each
// frame gets a mask shaped like one slice of a huge, slowly spinning wheel.
// The wheel is so big that, at any moment, only ONE slice covers the view,
// so exactly one frame is visible. As the wheel turns, the next slice
// slides over and the next frame appears. Result: a looping animation
// (tail swish, blink, breathing...) with no code running.

struct FrameLoop<Content: View>: View {
    let count: Int
    let period: TimeInterval
    let size: CGSize
    let content: (Int) -> Content

    init(count: Int, period: TimeInterval, size: CGSize,
         @ViewBuilder content: @escaping (Int) -> Content) {
        self.count = count
        self.period = period
        self.size = size
        self.content = content
    }

    var body: some View {
        ZStack {
            ForEach(0..<count, id: \.self) { i in
                content(i)
                    .frame(width: size.width, height: size.height)
                    .clipped()
                    .mask {
                        WheelSliceMask(index: i, count: count, period: period, size: size)
                    }
            }
        }
        .frame(width: size.width, height: size.height)
    }
}

/// One slice of the giant spinning wheel. The view sits near the top rim of the wheel.
private struct WheelSliceMask: View {
    let index: Int
    let count: Int
    let period: TimeInterval
    let size: CGSize

    var body: some View {
        let side = max(size.width, size.height)
        let radius = side * max(8, Double(count) * 0.5)
        let slice = 360.0 / Double(count)
        // The view is straight above the wheel's centre (angle -90°).
        // Frame i is visible while the wheel has turned between i and i+1 slices.
        let start = -90.0 - Double(index + 1) * slice
        let end = -90.0 - Double(index) * slice + 0.4   // tiny overlap hides seams
        Wedge(startDegrees: start, endDegrees: end)
            .fill(Color.black)
            .frame(width: radius * 2, height: radius * 2)
            .clockHandRotationEffect(period: .custom(period))
            .offset(y: radius - side)
    }
}

/// A pie slice drawn with explicit points (no ambiguity about arc direction).
struct Wedge: Shape {
    var startDegrees: Double
    var endDegrees: Double

    func path(in rect: CGRect) -> Path {
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let r = rect.width / 2
        var p = Path()
        p.move(to: c)
        let steps = 12
        for k in 0...steps {
            let deg = startDegrees + (endDegrees - startDegrees) * Double(k) / Double(steps)
            let a = CGFloat(deg) * .pi / 180
            p.addLine(to: CGPoint(x: c.x + r * cos(a), y: c.y + r * sin(a)))
        }
        p.closeSubpath()
        return p
    }
}

extension View {
    /// Spins forever, like a clock hand, once every `period` seconds.
    func spinForever(period: TimeInterval, anchor: UnitPoint = .center) -> some View {
        clockHandRotationEffect(period: .custom(period), anchor: anchor)
    }
}
