import SwiftUI

enum EyeStyle { case open, wide, happy, closed, sleepy }

/// The cat, drawn entirely with shapes, in a 120 × 100 box.
struct CatView: View {
    let state: CatState

    var body: some View {
        Group {
            if state.pose == .sleeping {
                SleepingCat()
            } else {
                SittingCat(pose: state.pose, eyes: eyeStyle, blush: state.reaction == .petted)
            }
        }
        .frame(width: 120, height: 100)
        .contentShape(Rectangle())
    }

    private var eyeStyle: EyeStyle {
        switch state.reaction {
        case .petted, .eating, .full: return .happy
        case .playing, .wokeUp: return .wide
        case .tooTired, .grumpy: return .sleepy
        default:
            return state.mood == .tired ? .sleepy : .open
        }
    }
}

// MARK: - Sitting

struct SittingCat: View {
    let pose: CatPose
    let eyes: EyeStyle
    let blush: Bool

    var body: some View {
        ZStack {
            SwishingTail(fast: pose == .playing)
                .position(x: 98, y: 54)

            // Body + belly
            Ellipse().fill(Color.fur)
                .frame(width: 64, height: 54)
                .position(x: 60, y: 74)
            Capsule().fill(Color.furDark)
                .frame(width: 4, height: 14)
                .rotationEffect(.degrees(-20))
                .position(x: 36, y: 70)
            Capsule().fill(Color.furDark)
                .frame(width: 4, height: 14)
                .rotationEffect(.degrees(20))
                .position(x: 84, y: 70)
            Ellipse().fill(Color.cream)
                .frame(width: 34, height: 36)
                .position(x: 60, y: 80)

            // Paws
            Ellipse().fill(Color.cream)
                .frame(width: 17, height: 11)
                .position(x: 49, y: 97)
            if pose == .playing {
                BattingPaw().position(x: 86, y: 78)
            } else {
                Ellipse().fill(Color.cream)
                    .frame(width: 17, height: 11)
                    .position(x: 71, y: 97)
            }

            CatHead(eyes: eyes, blush: blush, mouthOpen: pose == .playing)
                .rotationEffect(.degrees(pose == .eating ? 14 : 0))
                .position(x: pose == .eating ? 66 : 60, y: pose == .eating ? 46 : 38)
        }
        .frame(width: 120, height: 100)
    }
}

struct CatHead: View {
    let eyes: EyeStyle
    let blush: Bool
    let mouthOpen: Bool

    var body: some View {
        ZStack {
            // Ears
            Group {
            Triangle().fill(Color.fur)
                .frame(width: 19, height: 23)
                .rotationEffect(.degrees(-18))
                .position(x: 16, y: 13)
            Triangle().fill(Color.catPink)
                .frame(width: 9, height: 12)
                .rotationEffect(.degrees(-18))
                .position(x: 17, y: 16)
            Triangle().fill(Color.fur)
                .frame(width: 19, height: 23)
                .rotationEffect(.degrees(18))
                .position(x: 54, y: 13)
            Triangle().fill(Color.catPink)
                .frame(width: 9, height: 12)
                .rotationEffect(.degrees(18))
                .position(x: 53, y: 16)
            }

            // Head
            Ellipse().fill(Color.fur)
                .frame(width: 56, height: 50)
                .position(x: 35, y: 34)

            // Forehead stripes
            Group {
            Capsule().fill(Color.furDark).frame(width: 3, height: 8).position(x: 29, y: 16)
            Capsule().fill(Color.furDark).frame(width: 3, height: 10).position(x: 35, y: 15)
            Capsule().fill(Color.furDark).frame(width: 3, height: 8).position(x: 41, y: 16)
            }

            // Muzzle
            Ellipse().fill(Color.cream)
                .frame(width: 28, height: 16)
                .position(x: 35, y: 45)

            // Eyes (blink on their own when open)
            Group {
                if eyes == .open {
                    FrameLoop(count: 25, period: 5, size: CGSize(width: 44, height: 16)) { i in
                        Eyes(style: i == 0 ? .closed : .open)
                    }
                } else {
                    Eyes(style: eyes)
                }
            }
            .position(x: 35, y: 32)

            if blush {
                Ellipse().fill(Color.catPink.opacity(0.6))
                    .frame(width: 10, height: 6).position(x: 15, y: 42)
                Ellipse().fill(Color.catPink.opacity(0.6))
                    .frame(width: 10, height: 6).position(x: 55, y: 42)
            }

            // Nose + mouth
            Triangle().fill(Color.catPink)
                .frame(width: 7, height: 5)
                .rotationEffect(.degrees(180))
                .position(x: 35, y: 41)
            if mouthOpen {
                Ellipse().fill(Color.catPink)
                    .frame(width: 7, height: 6)
                    .position(x: 35, y: 48)
            }
            MouthShape()
                .stroke(Color.ink, style: StrokeStyle(lineWidth: 1.3, lineCap: .round))
                .frame(width: 12, height: 4)
                .position(x: 35, y: 45)

            Whiskers()
                .stroke(Color.ink.opacity(0.45), style: StrokeStyle(lineWidth: 1, lineCap: .round))
                .frame(width: 70, height: 60)
        }
        .frame(width: 70, height: 60)
    }
}

struct Whiskers: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 22, y: 43)); p.addLine(to: CGPoint(x: 4, y: 40))
        p.move(to: CGPoint(x: 22, y: 46)); p.addLine(to: CGPoint(x: 3, y: 47))
        p.move(to: CGPoint(x: 48, y: 43)); p.addLine(to: CGPoint(x: 66, y: 40))
        p.move(to: CGPoint(x: 48, y: 46)); p.addLine(to: CGPoint(x: 67, y: 47))
        return p
    }
}

/// Both eyes in a 44 × 16 box.
struct Eyes: View {
    let style: EyeStyle

    var body: some View {
        ZStack {
            eye.position(x: 11, y: 8)
            eye.position(x: 33, y: 8)
        }
        .frame(width: 44, height: 16)
    }

    @ViewBuilder private var eye: some View {
        switch style {
        case .open:
            ZStack {
                Ellipse().fill(Color.ink).frame(width: 9, height: 11)
                Circle().fill(Color.white).frame(width: 3.5, height: 3.5).offset(x: 1.5, y: -2)
            }
        case .wide:
            ZStack {
                Ellipse().fill(Color.ink).frame(width: 11, height: 13)
                Circle().fill(Color.white).frame(width: 4.5, height: 4.5).offset(x: 2, y: -2.5)
                Circle().fill(Color.white).frame(width: 2, height: 2).offset(x: -2, y: 2.5)
            }
        case .happy:
            ArcUp()
                .stroke(Color.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .frame(width: 10, height: 5)
        case .closed:
            ArcDown()
                .stroke(Color.ink, style: StrokeStyle(lineWidth: 2.2, lineCap: .round))
                .frame(width: 10, height: 4)
        case .sleepy:
            ZStack {
                Ellipse().fill(Color.ink).frame(width: 9, height: 11)
                Rectangle().fill(Color.fur).frame(width: 12, height: 6).offset(y: -3.5)
                Rectangle().fill(Color.ink).frame(width: 11, height: 1.6).offset(y: -0.5)
            }
            .frame(width: 12, height: 12)
            .clipped()
        }
    }
}

// MARK: - Tail

/// Tail drawn in a 76 × 76 box, base at (22, 70).
struct TailDrawing: View {
    var body: some View {
        ZStack {
            TailPath()
                .stroke(Color.fur, style: StrokeStyle(lineWidth: 10, lineCap: .round))
            TailPath()
                .trim(from: 0.82, to: 1)
                .stroke(Color.furDark, style: StrokeStyle(lineWidth: 10, lineCap: .round))
        }
        .frame(width: 76, height: 76)
    }
}

struct TailPath: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 22, y: 70))
        p.addCurve(to: CGPoint(x: 52, y: 22),
                   control1: CGPoint(x: 56, y: 66),
                   control2: CGPoint(x: 64, y: 38))
        p.addQuadCurve(to: CGPoint(x: 42, y: 16), control: CGPoint(x: 46, y: 11))
        return p
    }
}

/// The tail swishing back and forth, forever, on the home screen.
struct SwishingTail: View {
    var fast: Bool = false

    var body: some View {
        let frames = 20
        FrameLoop(count: frames, period: fast ? 1.2 : 2.4, size: CGSize(width: 76, height: 76)) { i in
            TailDrawing()
                .rotationEffect(.degrees(16 * sin(Double(i) / Double(frames) * 2 * .pi)),
                                anchor: UnitPoint(x: 22.0 / 76.0, y: 70.0 / 76.0))
        }
    }
}

/// A paw batting at the yarn.
struct BattingPaw: View {
    var body: some View {
        let frames = 12
        FrameLoop(count: frames, period: 1.2, size: CGSize(width: 26, height: 34)) { i in
            Ellipse().fill(Color.cream)
                .frame(width: 16, height: 12)
                .offset(x: 2 * sin(Double(i) / Double(frames) * 2 * .pi),
                        y: 8 - 10 * abs(sin(Double(i) / Double(frames) * .pi)))
        }
    }
}

// MARK: - Sleeping (curled up)

struct SleepingCat: View {
    var body: some View {
        ZStack {
            // Breathing body
            FrameLoop(count: 16, period: 4, size: CGSize(width: 120, height: 100)) { i in
                Ellipse().fill(Color.fur)
                    .frame(width: 96, height: 48)
                    .scaleEffect(x: 1, y: 1 + 0.05 * (1 - cos(Double(i) / 16 * 2 * .pi)) / 2,
                                 anchor: .bottom)
                    .position(x: 64, y: 70)
            }

            Group {
            Capsule().fill(Color.furDark).frame(width: 4, height: 14)
                .rotationEffect(.degrees(-10)).position(x: 62, y: 54)
            Capsule().fill(Color.furDark).frame(width: 4, height: 15)
                .position(x: 75, y: 52)
            Capsule().fill(Color.furDark).frame(width: 4, height: 14)
                .rotationEffect(.degrees(10)).position(x: 88, y: 54)

            // Tail wrapped around the front
            SleepTailPath()
                .stroke(Color.fur, style: StrokeStyle(lineWidth: 10, lineCap: .round))
            SleepTailPath()
                .trim(from: 0.8, to: 1)
                .stroke(Color.furDark, style: StrokeStyle(lineWidth: 10, lineCap: .round))
            }

            // Head resting on the left
            Group {
            Triangle().fill(Color.fur).frame(width: 15, height: 17)
                .rotationEffect(.degrees(-28)).position(x: 19, y: 50)
            Triangle().fill(Color.catPink).frame(width: 7, height: 9)
                .rotationEffect(.degrees(-28)).position(x: 20, y: 53)
            Triangle().fill(Color.fur).frame(width: 15, height: 17)
                .rotationEffect(.degrees(12)).position(x: 46, y: 47)
            Triangle().fill(Color.catPink).frame(width: 7, height: 9)
                .rotationEffect(.degrees(12)).position(x: 46, y: 50)
            Ellipse().fill(Color.fur).frame(width: 48, height: 40).position(x: 33, y: 67)
            Ellipse().fill(Color.cream).frame(width: 22, height: 12).position(x: 33, y: 77)
            ArcDown().stroke(Color.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 9, height: 4).position(x: 24, y: 66)
            ArcDown().stroke(Color.ink, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                .frame(width: 9, height: 4).position(x: 42, y: 66)
            Triangle().fill(Color.catPink).frame(width: 6, height: 4)
                .rotationEffect(.degrees(180)).position(x: 33, y: 74)
            }

            // Floating Zzz
            SleepyZs().position(x: 30, y: 24)
        }
        .frame(width: 120, height: 100)
    }
}

struct SleepTailPath: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: 106, y: 74))
        p.addQuadCurve(to: CGPoint(x: 46, y: 92), control: CGPoint(x: 112, y: 100))
        return p
    }
}

struct SleepyZs: View {
    var body: some View {
        let frames = 15
        FrameLoop(count: frames, period: 3, size: CGSize(width: 44, height: 44)) { i in
            let p = Double(i) / Double(frames)
            let q = (p + 0.5).truncatingRemainder(dividingBy: 1)
            ZStack {
                Text("z")
                    .font(.system(size: 11 + 5 * p, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.zzz.opacity(1 - p))
                    .offset(x: -8 + 10 * p, y: 14 - 26 * p)
                Text("z")
                    .font(.system(size: 11 + 5 * q, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color.zzz.opacity(1 - q))
                    .offset(x: -8 + 10 * q, y: 14 - 26 * q)
            }
        }
    }
}
