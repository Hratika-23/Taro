import SwiftUI

// Clay-style Taro, drawn with SwiftUI Canvas.
// Local coordinates: facing right, feet on y = 0 (same numbers as the web preview).

struct KPose {
    var bx: CGFloat, by: CGFloat, brx: CGFloat, bry: CGFloat, brot: CGFloat
    var hx: CGFloat, hy: CGFloat, hrot: CGFloat
    var fx: CGFloat, hindx: CGFloat, legShow: CGFloat
    var tx: CGFloat, ty: CGFloat, ta: CGFloat, tc: CGFloat
    var haunch: CGFloat, paws: CGFloat, raise: CGFloat

    static let stand = KPose(bx: -2, by: -15, brx: 18, bry: 12.5, brot: 0, hx: 15, hy: -33, hrot: 0,
                             fx: 8, hindx: -11, legShow: 1, tx: -18, ty: -18, ta: -2.2, tc: 0.13,
                             haunch: 0, paws: 0, raise: 0)
    static var sit: KPose {
        var p = stand
        p.bx = 0; p.by = -16; p.brx = 13.5; p.bry = 15.5; p.hx = 3; p.hy = -40; p.fx = 6; p.hindx = -2
        p.legShow = 0; p.tx = -9; p.ty = -6; p.ta = 3.3; p.tc = 0.14; p.haunch = 1
        return p
    }
    static var lie: KPose {
        var p = stand
        p.bx = 0; p.by = -10; p.brx = 20; p.bry = 10; p.hx = 16; p.hy = -24; p.legShow = 0; p.paws = 1
        p.tx = -19; p.ty = -7; p.ta = 3.1; p.tc = 0.03
        return p
    }
    static var eat: KPose { var p = stand; p.by = -14; p.brot = 0.14; p.hx = 21; p.hy = -10; p.hrot = 0.22; p.ta = -2.0; return p }
    static var stretch: KPose {
        var p = stand
        p.by = -13; p.brx = 20; p.bry = 11; p.brot = 0.3; p.hx = 21; p.hy = -13; p.hrot = 0.15
        p.fx = 16; p.hindx = -13; p.ta = -2.5; p.tc = 0.05
        return p
    }
    static var crouch: KPose { var p = stand; p.by = -10; p.bry = 10; p.brot = 0.04; p.hx = 16; p.hy = -24; p.ta = 3.05; p.tc = -0.03; return p }
    static var play: KPose { var p = crouch; p.raise = 1; return p }
}

struct Face {
    var eyes = "open"     // open, big, happy, closed
    var mouth = "w"       // w, open, lick
    var lick: CGFloat = 0
    var tilt: CGFloat = 0
    var back = false
}

enum Kawaii {
    static func furClay(_ g: GraphicsContext, _ p: Path, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        clay(g, p, cx, cy, r, Pal.fur, Pal.furLight, Pal.furDeep)
    }
    static func creamClay(_ g: GraphicsContext, _ p: Path, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat) {
        clay(g, p, cx, cy, r, Pal.cream, .white, Pal.creamShade, gloss: 0.5)
    }

    static func leg(_ g: GraphicsContext, _ x: CGFloat, _ top: CGFloat, swing: CGFloat, lift: CGFloat, far: Bool) {
        let fx = x + swing, fy = -lift
        let mx = (x + fx) / 2, my = (top + fy - 3) / 2, len = max(3, fy - 3 - top)
        clay(g, rrect(mx - 3.6, top, 7.2, len + 2, 3.6), mx, my, 6,
             far ? Pal.furDeep : Pal.fur, far ? Pal.fur : Pal.furLight, far ? Color(hex: 0xC9773A) : Pal.furDeep, gloss: 0.2)
        creamClay(g, ell(fx + 1, fy - 2.6, 4.6, 3.3), fx + 1, fy - 2.6, 4.6)
    }

    /// Tail as a rope of clay beads. `phase` drives the swish (0…2π).
    static func tail(_ g: GraphicsContext, _ p: KPose, phase: CGFloat, wag: CGFloat) {
        var x = p.tx, y = p.ty
        var pts = [P(x, y)]
        for i in 0..<12 {
            let fi = CGFloat(i)
            let a = p.ta + fi * p.tc + wag * sin(phase - fi * 0.42) * (0.25 + fi / 12)
            x += cos(a) * 2.8; y += sin(a) * 2.8
            pts.append(P(x, y))
        }
        for (i, q) in pts.enumerated() {
            let r = 3.9 - CGFloat(i) * 0.06
            let striped = i >= 10 || i == 5 || i == 8
            clay(g, ell(q.x, q.y, r, r), q.x, q.y, r, striped ? Pal.stripe : Pal.fur, Pal.furLight, Pal.furDeep, gloss: 0.12)
        }
    }

    static func head(_ g0: GraphicsContext, hx: CGFloat, hy: CGFloat, hrot: CGFloat, face: Face) {
        var g = g0
        g.translateBy(x: hx, y: hy)
        g.rotate(by: .radians(Double(hrot + face.tilt)))
        g.scaleBy(x: 1.12, y: 1.12)
        for s: CGFloat in [-1, 1] {
            var ear = Path()
            ear.move(to: P(s * 3, -11))
            ear.addQuadCurve(to: P(s * 15, -22), control: P(s * 11, -27))
            ear.addQuadCurve(to: P(s * 15.5, -5), control: P(s * 18, -13))
            ear.closeSubpath()
            furClay(g, ear, s * 11, -14, 9)
            if face.back { continue }
            var inner = Path()
            inner.move(to: P(s * 6.5, -11))
            inner.addQuadCurve(to: P(s * 13.5, -19.5), control: P(s * 11.5, -22))
            inner.addQuadCurve(to: P(s * 13.5, -8.5), control: P(s * 15.2, -13))
            inner.closeSubpath()
            g.fill(inner, with: .linearGradient(Gradient(colors: [Color(hex: 0xFBC0CA), Pal.pink]), startPoint: P(0, -21), endPoint: P(0, -9)))
        }
        var shape = Path()
        shape.move(to: P(0, -14.5))
        shape.addCurve(to: P(18, 1.5), control1: P(12, -14.5), control2: P(18, -7))
        shape.addCurve(to: P(0, 13.5), control1: P(18, 10.5), control2: P(10, 13.5))
        shape.addCurve(to: P(-18, 1.5), control1: P(-10, 13.5), control2: P(-18, 10.5))
        shape.addCurve(to: P(0, -14.5), control1: P(-18, -7), control2: P(-12, -14.5))
        shape.closeSubpath()
        furClay(g, shape, 0, 0, 17)
        var marks = g
        marks.clip(to: shape)
        for x: CGFloat in [-4.5, 0, 4.5] {
            marks.fill(ell(x, face.back ? -6 : -12.5, 1.6, face.back ? 8 : 4), with: .color(Color(hex: 0xD67837, 0.45)))
        }
        if face.back { return }

        var muzzle = Path()
        muzzle.addPath(ell(-4.2, 6.6, 6.2, 5)); muzzle.addPath(ell(4.2, 6.6, 6.2, 5))
        creamClay(g, muzzle, 0, 6, 9)

        let ex: CGFloat = 6.8, ey: CGFloat = 0
        let lineStyle = StrokeStyle(lineWidth: 1.9, lineCap: .round)
        if face.eyes == "happy" || face.eyes == "closed" {
            for s: CGFloat in [-1, 1] {
                var e = Path()
                if face.eyes == "happy" {
                    e.move(to: P(s * ex - 3.2, ey + 1.4)); e.addQuadCurve(to: P(s * ex + 3.2, ey + 1.4), control: P(s * ex, ey - 3.8))
                } else {
                    e.move(to: P(s * ex - 3.2, ey)); e.addQuadCurve(to: P(s * ex + 3.2, ey), control: P(s * ex, ey + 3))
                }
                g.stroke(e, with: .color(Pal.eye), style: lineStyle)
            }
        } else {
            let big: CGFloat = face.eyes == "big" ? 1.15 : 1
            for s: CGFloat in [-1, 1] {
                var sh = g
                sh.addFilter(.shadow(color: Color(hex: 0x3C1E14, 0.25), radius: 0.8, x: 0, y: 0.8))
                sh.fill(ell(s * ex, ey, 3.5 * big, 4 * big),
                        with: .radialGradient(Gradient(colors: [Color(hex: 0x4A3B36), Pal.eye]), center: P(s * ex - 1, ey - 1.5), startRadius: 0.3, endRadius: 4 * big))
                g.fill(ell(s * ex - 1.1, ey - 1.6, 1.5 * big, 1.5 * big), with: .color(.white))
                g.fill(ell(s * ex + 1.3, ey + 1.5, 0.65, 0.65), with: .color(.white))
            }
        }
        for s: CGFloat in [-1, 1] {
            g.fill(ell(s * 11.5, 5, 4.4, 3), with: .radialGradient(Gradient(colors: [Color(hex: 0xFF8CA5, 0.75), Color(hex: 0xFF8CA5, 0)]),
                                                                    center: P(s * 11.5, 5), startRadius: 0, endRadius: 4.2))
        }
        var nose = Path()
        nose.move(to: P(-1.7, 3.3)); nose.addQuadCurve(to: P(1.7, 3.3), control: P(0, 2.6))
        nose.addQuadCurve(to: P(0, 5.2), control: P(0.5, 5.2)); nose.addQuadCurve(to: P(-1.7, 3.3), control: P(-0.5, 5.2))
        g.fill(nose, with: .color(Pal.pink))
        let mouthColor = Color(hex: 0x7A4A3E)
        if face.mouth == "open" {
            var m = Path(); m.move(to: P(-2.6, 6.4)); m.addQuadCurve(to: P(2.6, 6.4), control: P(0, 11)); m.closeSubpath()
            g.fill(m, with: .color(Color(hex: 0xE2687A)))
            g.fill(ell(0, 8.6, 1.3, 0.9), with: .color(Color(hex: 0xFF9AAA)))
        } else if face.mouth == "lick" {
            var m = Path(); m.move(to: P(0, 5.2)); m.addLine(to: P(0, 6.4))
            g.stroke(m, with: .color(mouthColor), lineWidth: 0.9)
            g.fill(ell(0, 8.2 + face.lick * 2, 1.9, 1.5 + face.lick * 1.5), with: .color(Color(hex: 0xF2808F)))
        } else {
            var m = Path()
            m.move(to: P(0, 5.2)); m.addLine(to: P(0, 6.3))
            m.move(to: P(-2.8, 6.6)); m.addQuadCurve(to: P(0, 6.3), control: P(-1.4, 8.3)); m.addQuadCurve(to: P(2.8, 6.6), control: P(1.4, 8.3))
            g.stroke(m, with: .color(mouthColor), style: StrokeStyle(lineWidth: 0.9, lineCap: .round))
        }
        var wh = Path()
        for s: CGFloat in [-1, 1] {
            wh.move(to: P(s * 9, 6)); wh.addLine(to: P(s * 17, 4.6))
            wh.move(to: P(s * 9, 7.6)); wh.addLine(to: P(s * 17, 8.6))
        }
        g.stroke(wh, with: .color(Color(hex: 0x966E55, 0.4)), lineWidth: 0.6)
    }

    /// Closed eyes drawn over open ones (used for blinking).
    static func blinkPatch(_ g0: GraphicsContext, hx: CGFloat, hy: CGFloat, hrot: CGFloat, tilt: CGFloat) {
        var g = g0
        g.translateBy(x: hx, y: hy); g.rotate(by: .radians(Double(hrot + tilt))); g.scaleBy(x: 1.12, y: 1.12)
        for s: CGFloat in [-1, 1] {
            g.fill(ell(s * 6.8, 0, 4.4, 5), with: .radialGradient(Gradient(colors: [Pal.furLight, Pal.fur]), center: P(s * 6.8 - 2, -3), startRadius: 0, endRadius: 8))
            var e = Path(); e.move(to: P(s * 6.8 - 3.2, 0)); e.addQuadCurve(to: P(s * 6.8 + 3.2, 0), control: P(s * 6.8, 3))
            g.stroke(e, with: .color(Pal.eye), style: StrokeStyle(lineWidth: 1.9, lineCap: .round))
        }
    }

    /// The whole cat except the tail (the tail is animated separately, behind).
    static func body(_ g: GraphicsContext, _ p: KPose, face: Face, armTo: CGPoint?, drawTail: Bool = false) {
        let legTop = p.by + p.bry * 0.35
        if p.legShow > 0.05 {
            leg(g, p.fx - 4, legTop, swing: 0, lift: 0, far: true)
            leg(g, p.hindx - 4, legTop, swing: 0, lift: 0, far: true)
        }
        if drawTail { tail(g, p, phase: 0, wag: 0) }
        if p.haunch > 0.05 {
            furClay(g, ell(-6, -8, 11, 8.5), -6, -8, 11)
            creamClay(g, ell(3, -2.6, 5, 3.3), 3, -2.6, 5)
        }
        let bodyPath = ell(p.bx, p.by, p.brx, p.bry, p.brot)
        furClay(g, bodyPath, p.bx, p.by, max(p.brx, p.bry))
        var c = g
        c.clip(to: bodyPath)
        c.translateBy(x: p.bx, y: p.by); c.rotate(by: .radians(Double(p.brot)))
        c.fill(ell(p.brx * 0.2, p.bry * 0.75, p.brx * 0.7, p.bry * 0.55),
               with: .radialGradient(Gradient(stops: [.init(color: Pal.cream, location: 0), .init(color: Pal.cream, location: 0.75), .init(color: Pal.cream.opacity(0), location: 1)]),
                                     center: P(p.brx * 0.2, p.bry * 0.7), startRadius: 1, endRadius: p.brx * 0.7))
        for sx: CGFloat in [-0.55, -0.2, 0.15] {
            c.fill(ell(p.brx * sx, -p.bry * 0.75, 2, p.bry * 0.32), with: .color(Color(hex: 0xD67837, 0.35)))
        }
        if p.legShow > 0.05 {
            leg(g, p.hindx, legTop + 1, swing: 0, lift: 0, far: false)
            if p.raise > 0.05 {
                leg(g, p.fx + 2, legTop + 1, swing: 7, lift: 9, far: false)
            } else {
                leg(g, p.fx, legTop + 1, swing: 0, lift: 0, far: false)
            }
        }
        if p.paws > 0.05 || p.haunch > 0.05 {
            let px = p.paws > p.haunch ? p.hx + 2 : 6
            for dx: CGFloat in [-4.5, 4.5] { creamClay(g, ell(px + dx, -2.8, 4.8, 3.4), px + dx, -2.8, 4.8) }
        }
        head(g, hx: p.hx, hy: p.hy, hrot: p.hrot, face: face)
        if let a = armTo {
            let sx = p.bx + 6, sy = p.by - 6
            let ang = atan2(a.y - sy, a.x - sx), len = hypot(a.x - sx, a.y - sy)
            let arm = rrect(0, -3.5, len, 7, 3.5)
                .applying(CGAffineTransform(rotationAngle: ang).concatenating(CGAffineTransform(translationX: sx, y: sy)))
            clay(g, arm, (sx + a.x) / 2, (sy + a.y) / 2, 8, Pal.fur, Pal.furLight, Pal.furDeep, gloss: 0.2)
            creamClay(g, ell(a.x, a.y, 4.4, 3.6), a.x, a.y, 4.4)
        }
    }

    /// Curled up asleep. `breath` 0…1 puffs the body a little.
    static func curled(_ g0: GraphicsContext, breath: CGFloat) {
        var g = g0
        g.translateBy(x: 0, y: -11); g.scaleBy(x: 1, y: 1 + breath * 0.035); g.translateBy(x: 0, y: 11)
        furClay(g, ell(-2, -11, 23, 12), -2, -11, 23)
        for x: CGFloat in [-14, -7, 0] { g.fill(ell(x, -20, 2, 3.6), with: .color(Color(hex: 0xD67837, 0.35))) }
        for i in 0..<13 {
            let u = CGFloat(i) / 12, bx = -21 + 35 * u, by = -3 + sin(u * .pi) * 3.5
            clay(g0, ell(bx, by, 3.8, 3.8), bx, by, 3.8, i > 10 ? Pal.stripe : Pal.fur, Pal.furLight, Pal.furDeep, gloss: 0.1)
        }
        head(g0, hx: 11, hy: -15, hrot: 0.18, face: Face(eyes: "closed"))
    }
}

/// Taro as a view: body + swishing tail + blinking, placed with feet at the view's anchor.
struct CatFigure: View {
    var pose: KPose
    var face = Face()
    var armTo: CGPoint? = nil
    var curled = false
    var wag: CGFloat = 0.28
    var swishPeriod: Double = 2.6

    // local box: x −52…52, y −80…8 (feet at 52, 80)
    static let box = CGSize(width: 104, height: 88)
    static let origin = CGPoint(x: 52, y: 80)

    var body: some View {
        ZStack {
            if curled {
                FrameLoop(count: 10, period: 4, size: Self.box) { i in
                    Canvas { ctx, _ in
                        var g = ctx; g.translateBy(x: Self.origin.x, y: Self.origin.y)
                        Kawaii.curled(g, breath: (1 - cos(CGFloat(i) / 10 * 2 * .pi)) / 2)
                    }
                }
            } else {
                // tail swish behind the body
                FrameLoop(count: 16, period: swishPeriod, size: Self.box) { i in
                    Canvas { ctx, _ in
                        var g = ctx; g.translateBy(x: Self.origin.x, y: Self.origin.y)
                        Kawaii.tail(g, pose, phase: CGFloat(i) / 16 * 2 * .pi, wag: wag)
                    }
                }
                Canvas { ctx, _ in
                    var g = ctx; g.translateBy(x: Self.origin.x, y: Self.origin.y)
                    Kawaii.body(g, pose, face: face, armTo: armTo)
                }
                if face.eyes == "open" || face.eyes == "big" {
                    FrameLoop(count: 22, period: 4.4, size: Self.box) { i in
                        Canvas { ctx, _ in
                            guard i == 0 else { return }
                            var g = ctx; g.translateBy(x: Self.origin.x, y: Self.origin.y)
                            Kawaii.blinkPatch(g, hx: pose.hx, hy: pose.hy, hrot: pose.hrot, tilt: face.tilt)
                        }
                    }
                }
            }
        }
        .frame(width: Self.box.width, height: Self.box.height)
    }

    /// Place so the feet land on `point`, facing `dir`, at `scale`.
    func placed(at point: CGPoint, dir: CGFloat, scale: CGFloat) -> some View {
        self
            .scaleEffect(x: dir * scale, y: scale, anchor: UnitPoint(x: Self.origin.x / Self.box.width, y: Self.origin.y / Self.box.height))
            .position(x: point.x, y: point.y - (Self.origin.y - Self.box.height / 2))
    }
}
