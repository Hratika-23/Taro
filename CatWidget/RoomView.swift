import SwiftUI
import WidgetKit
import AppIntents
import ClockHandRotationKit

/// The cat's whole room (large widget). Designed at 364 × 382 points.
struct RoomView: View {
    let state: CatState
    let date: Date

    static let size = CGSize(width: 364, height: 382)

    private var evening: Bool {
        let h = Calendar.current.component(.hour, from: date)
        return h >= 19 || h < 6
    }

    private var catPosition: CGPoint {
        switch state.pose {
        case .sitting:  return CGPoint(x: 176, y: 262)
        case .eating:   return CGPoint(x: 180, y: 270)
        case .playing:  return CGPoint(x: 256, y: 262)
        case .sleeping: return CGPoint(x: 112, y: 284)
        }
    }

    var body: some View {
        let cat = catPosition
        ZStack {
            // Wall with polka dots
            Group {
            Color.wall
            WallDots()

            // Floor
            Rectangle().fill(Color.floorWood)
                .frame(width: 364, height: 128)
                .position(x: 182, y: 318)
            ForEach(0..<4, id: \.self) { i in
                Rectangle().fill(Color.floorLine)
                    .frame(width: 364, height: 1.5)
                    .position(x: 182, y: 286 + Double(i) * 30)
            }
            Rectangle().fill(Color.baseboard)
                .frame(width: 364, height: 10)
                .position(x: 182, y: 255)

            // Wall decor
            WindowView(evening: evening).position(x: 84, y: 118)
            FishPicture().position(x: 196, y: 104)
            WallClock().position(x: 304, y: 108)

            StatsBar(state: state).position(x: 182, y: 30)
            }

            // Lamp = lights on / off (sleep / wake)
            Group {
            Button(intent: ToggleSleepIntent()) {
                LampView(on: !state.isSleeping)
            }
            .buttonStyle(.plain)
            .position(x: 30, y: 226)

            // Bed (also toggles a nap)
            Button(intent: ToggleSleepIntent()) {
                BedView()
            }
            .buttonStyle(.plain)
            .position(x: 112, y: 312)

            // Food bowl
            Button(intent: FeedCatIntent()) {
                BowlView(full: state.pose == .eating)
            }
            .buttonStyle(.plain)
            .position(x: 240, y: 330)

            // Yarn ball
            Button(intent: PlayWithCatIntent()) {
                YarnView(rolling: state.pose == .playing)
            }
            .buttonStyle(.plain)
            .position(x: 326, y: 334)
            }

            // The cat — tap him to pet
            Button(intent: PetCatIntent()) {
                CatView(state: state)
            }
            .buttonStyle(.plain)
            .position(cat)

            if state.reaction == .petted || state.reaction == .purrInSleep {
                FloatingHearts().position(x: cat.x + 34, y: cat.y - 36)
            }

            // Lights off
            if state.isSleeping {
                Color(red: 0.06, green: 0.07, blue: 0.24)
                    .opacity(0.36)
                    .allowsHitTesting(false)
            }

            if let msg = state.message {
                Bubble(text: msg, fontSize: 13)
                    .position(x: min(max(cat.x, 86), 278),
                              y: cat.y - (state.pose == .sleeping ? 20 : 66))
                    .transition(.scale(scale: 0.5).combined(with: .opacity))
                    .id(msg)
            }
        }
        .frame(width: 364, height: 382)
    }
}

// MARK: - Room pieces

struct WallDots: View {
    var body: some View {
        ZStack {
            ForEach(0..<7, id: \.self) { row in
                ForEach(0..<10, id: \.self) { col in
                    Circle().fill(Color.wallDot)
                        .frame(width: 5, height: 5)
                        .position(x: 18 + Double(col) * 37 + (row % 2 == 0 ? 0 : 18),
                                  y: 58 + Double(row) * 30)
                }
            }
        }
        .frame(width: 364, height: 382)
    }
}

struct StatsBar: View {
    let state: CatState

    var body: some View {
        HStack(spacing: 10) {
            Text(CatInfo.name)
                .font(.system(size: 14, weight: .bold, design: .rounded))
                .foregroundStyle(Color.ink)
            Meter(icon: "🍗", value: state.fullness, color: Color(red: 0.95, green: 0.55, blue: 0.30))
            Meter(icon: "🧶", value: state.fun, color: Color.yarn)
            Meter(icon: "⚡️", value: state.energy, color: Color(red: 0.95, green: 0.78, blue: 0.20))
            Text("♥ \(state.hearts)")
                .font(.system(size: 12, weight: .semibold, design: .rounded))
                .foregroundStyle(Color(red: 0.90, green: 0.35, blue: 0.45))
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(Capsule().fill(Color.white.opacity(0.7)))
    }
}

struct Meter: View {
    let icon: String
    let value: Double
    let color: Color

    var body: some View {
        HStack(spacing: 3) {
            Text(icon).font(.system(size: 11))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.1)).frame(width: 40, height: 7)
                Capsule().fill(color).frame(width: max(4, 40 * value / 100), height: 7)
            }
        }
    }
}

struct WindowView: View {
    let evening: Bool

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 6).fill(Color.white)
                .frame(width: 100, height: 96)
            RoundedRectangle(cornerRadius: 3)
                .fill(LinearGradient(
                    colors: evening
                        ? [Color(red: 0.10, green: 0.12, blue: 0.32), Color(red: 0.30, green: 0.22, blue: 0.50)]
                        : [Color(red: 0.55, green: 0.80, blue: 0.98), Color(red: 0.85, green: 0.94, blue: 1.0)],
                    startPoint: .top, endPoint: .bottom))
                .frame(width: 88, height: 84)
            if evening {
                Circle().fill(Color(red: 1.0, green: 0.96, blue: 0.75))
                    .frame(width: 16, height: 16).offset(x: 22, y: -22)
                ForEach(0..<6, id: \.self) { i in
                    Circle().fill(Color.white.opacity(0.9))
                        .frame(width: 2.5, height: 2.5)
                        .offset(x: [-30, -14, 4, -24, 10, 30][i], y: [-28, -10, -30, 16, 6, 20][i])
                }
            } else {
                Circle().fill(Color(red: 1.0, green: 0.85, blue: 0.35))
                    .frame(width: 18, height: 18).offset(x: 22, y: -22)
                Capsule().fill(Color.white).frame(width: 30, height: 10).offset(x: -16, y: 8)
                Capsule().fill(Color.white).frame(width: 18, height: 9).offset(x: -6, y: 2)
            }
            Rectangle().fill(Color.white).frame(width: 3, height: 84)
            Rectangle().fill(Color.white).frame(width: 88, height: 3)
            RoundedRectangle(cornerRadius: 6).fill(Color.curtain)
                .frame(width: 18, height: 106).offset(x: -52)
            RoundedRectangle(cornerRadius: 6).fill(Color.curtain)
                .frame(width: 18, height: 106).offset(x: 52)
            Rectangle().fill(Color.frameWood).frame(width: 120, height: 5).offset(y: -54)
            Rectangle().fill(Color.baseboard).frame(width: 110, height: 6).offset(y: 51)
        }
        .frame(width: 124, height: 112)
    }
}

struct FishPicture: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3).fill(Color.frameWood).frame(width: 50, height: 40)
            RoundedRectangle(cornerRadius: 2).fill(Color(red: 0.80, green: 0.92, blue: 0.98)).frame(width: 42, height: 32)
            Ellipse().fill(Color(red: 0.98, green: 0.55, blue: 0.40)).frame(width: 18, height: 11).offset(x: -2)
            Triangle().fill(Color(red: 0.98, green: 0.55, blue: 0.40))
                .frame(width: 10, height: 10).rotationEffect(.degrees(90)).offset(x: 11)
            Circle().fill(Color.ink).frame(width: 2.5, height: 2.5).offset(x: -7, y: -1)
        }
    }
}

/// A real ticking clock — iOS turns the hands itself.
struct WallClock: View {
    var body: some View {
        ZStack {
            Circle().fill(Color.white)
            Circle().stroke(Color.frameWood, lineWidth: 4)
            ForEach(0..<12, id: \.self) { i in
                Capsule().fill(Color.ink.opacity(0.5))
                    .frame(width: 2, height: i % 3 == 0 ? 6 : 3)
                    .offset(y: -20)
                    .rotationEffect(.degrees(Double(i) * 30))
            }
            hand(length: 13, width: 3.5, color: Color.ink)
                .clockHandRotationEffect(period: .hourHand)
            hand(length: 18, width: 2.5, color: Color.ink)
                .clockHandRotationEffect(period: .minuteHand)
            hand(length: 19, width: 1.2, color: Color.bowlRed)
                .clockHandRotationEffect(period: .secondHand)
            Circle().fill(Color.ink).frame(width: 5, height: 5)
        }
        .frame(width: 54, height: 54)
    }

    private func hand(length: CGFloat, width: CGFloat, color: Color) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(color).frame(width: width, height: length)
            Color.clear.frame(width: width, height: length)
        }
    }
}

struct LampView: View {
    let on: Bool

    var body: some View {
        ZStack {
            if on {
                Circle()
                    .fill(RadialGradient(colors: [Color(red: 1, green: 0.92, blue: 0.55).opacity(0.75), .clear],
                                         center: .center, startRadius: 2, endRadius: 40))
                    .frame(width: 80, height: 80)
                    .offset(y: -36)
            }
            VStack(spacing: 0) {
                Trapezoid()
                    .fill(on ? Color(red: 1.0, green: 0.88, blue: 0.50) : Color(red: 0.85, green: 0.80, blue: 0.70))
                    .frame(width: 40, height: 26)
                Rectangle().fill(Color.ink.opacity(0.6)).frame(width: 3, height: 84)
                Ellipse().fill(Color.ink.opacity(0.7)).frame(width: 30, height: 8)
            }
        }
        .frame(width: 56, height: 120)
        .contentShape(Rectangle())
    }
}

struct BedView: View {
    var body: some View {
        ZStack {
            Ellipse().fill(Color.bedRim).frame(width: 130, height: 52)
            Ellipse().fill(Color.bedInner).frame(width: 106, height: 32).offset(y: -4)
        }
        .frame(width: 132, height: 56)
    }
}

struct BowlView: View {
    let full: Bool

    var body: some View {
        ZStack {
            if full {
                Ellipse().fill(Color.kibble).frame(width: 44, height: 14).offset(y: -9)
                ForEach(0..<5, id: \.self) { i in
                    Circle().fill(Color.kibble.opacity(0.8))
                        .frame(width: 5, height: 5)
                        .offset(x: Double(i) * 8 - 16, y: -15 + Double(i % 2) * 2)
                }
            }
            UnevenRoundedRectangle(topLeadingRadius: 3, bottomLeadingRadius: 12,
                                   bottomTrailingRadius: 12, topTrailingRadius: 3)
                .fill(Color.bowlRed)
                .frame(width: 58, height: 22)
                .offset(y: 4)
            Text("🐟").font(.system(size: 9)).offset(y: 4)
        }
        .frame(width: 64, height: 44)
        .contentShape(Rectangle())
    }
}

struct YarnView: View {
    let rolling: Bool

    var body: some View {
        ZStack {
            YarnThread()
                .stroke(Color.yarnDark, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 60, height: 50)
            if rolling {
                ball.spinForever(period: 1.4)
            } else {
                ball
            }
        }
        .frame(width: 60, height: 50)
        .contentShape(Rectangle())
    }

    private var ball: some View {
        ZStack {
            Circle().fill(Color.yarn).frame(width: 38, height: 38)
            ForEach(0..<3, id: \.self) { i in
                Circle().trim(from: 0.05, to: 0.42)
                    .stroke(Color.yarnDark, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                    .frame(width: 26 - Double(i) * 6, height: 26 - Double(i) * 6)
                    .rotationEffect(.degrees(Double(i) * 70))
            }
        }
    }
}

struct YarnThread: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 24, y: 40))
        p.addQuadCurve(to: CGPoint(x: 2, y: 46), control: CGPoint(x: 12, y: 50))
        return p
    }
}

struct Bubble: View {
    let text: String
    let fontSize: CGFloat

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(Color.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.white)
                    .shadow(color: Color.black.opacity(0.15), radius: 2, y: 1)
            )
            .fixedSize()
    }
}

struct FloatingHearts: View {
    var body: some View {
        let frames = 14
        FrameLoop(count: frames, period: 2.1, size: CGSize(width: 50, height: 60)) { i in
            let p = Double(i) / Double(frames)
            let q = (p + 0.5).truncatingRemainder(dividingBy: 1)
            ZStack {
                Text("♥").font(.system(size: 15))
                    .foregroundStyle(Color(red: 0.95, green: 0.40, blue: 0.55).opacity(1 - p))
                    .offset(x: -6 + 6 * sin(p * 2 * .pi), y: 22 - 44 * p)
                Text("♥").font(.system(size: 11))
                    .foregroundStyle(Color(red: 0.95, green: 0.40, blue: 0.55).opacity(1 - q))
                    .offset(x: 10 + 5 * sin(q * 2 * .pi), y: 22 - 44 * q)
            }
        }
    }
}
