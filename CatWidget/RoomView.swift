import SwiftUI
import WidgetKit
import AppIntents

// MARK: - Room layout (same as the web preview)

enum Spot {
    static let bowl = CGPoint(x: 232, y: 292)
    static let water = CGPoint(x: 326, y: 300)
    static let bed = CGPoint(x: 96, y: 330)
    static let treeX: CGFloat = 180, treeLow: CGFloat = 206, treeTop: CGFloat = 150
    static let sill = CGPoint(x: 92, y: 168)
    static let yarn = CGPoint(x: 292, y: 352)
    static let pivot = CGPoint(x: 218, y: 214)   // pom-pom string
    static let ropeL: CGFloat = 30
    static let catScale: CGFloat = 0.92
}

/// Where and how Taro is drawn for each scene.
struct CatPlacement {
    var at: CGPoint
    var depth: CGFloat
    var dir: CGFloat
    var pose: KPose
    var face: Face
    var armTo: CGPoint? = nil
    var curled = false
    var wag: CGFloat = 0.28
    var swish: Double = 2.6

    var scale: CGFloat { depthScale(depth) * Spot.catScale }

    static func make(_ scene: CatScene, state: CatState, date: Date) -> CatPlacement {
        let dir = CGFloat(state.facing(at: date))
        let happy = state.reaction == .petted
        var face = Face(eyes: happy ? "happy" : "open", mouth: "w", tilt: happy ? -0.1 : 0)
        func reach(_ y: CGFloat) -> CGFloat { 21 * 1.12 * depthScale(y) * Spot.catScale }
        switch scene {
        case .sit:
            return CatPlacement(at: P(176, 302), depth: 302, dir: dir, pose: .sit, face: face)
        case .loaf:
            face.eyes = happy ? "happy" : "open"
            return CatPlacement(at: P(206, 342), depth: 342, dir: dir, pose: .lie, face: face, wag: 0.18, swish: 3.4)
        case .stretch:
            return CatPlacement(at: P(190, 324), depth: 324, dir: dir, pose: .stretch, face: Face(eyes: "happy"), wag: 0.12)
        case .eat:
            return CatPlacement(at: P(Spot.bowl.x - reach(Spot.bowl.y), Spot.bowl.y - 3), depth: Spot.bowl.y - 3, dir: 1, pose: .eat,
                                face: Face(eyes: "happy", mouth: "open"), wag: 0.35, swish: 1.8)
        case .drink:
            return CatPlacement(at: P(Spot.water.x - reach(Spot.water.y), Spot.water.y - 3), depth: Spot.water.y - 3, dir: 1, pose: .eat,
                                face: Face(eyes: "happy", mouth: "lick", lick: 1), wag: 0.3, swish: 2)
        case .yarn:
            let s = depthScale(Spot.yarn.y) * Spot.catScale
            return CatPlacement(at: P(Spot.yarn.x - 25 * s, Spot.yarn.y - 8), depth: Spot.yarn.y - 8, dir: 1, pose: .play,
                                face: Face(eyes: "big", mouth: "open"), wag: 0.55, swish: 1.1)
        case .pompom:
            let at = P(Spot.pivot.x - 22, 266), s = depthScale(266) * Spot.catScale
            let ball = P(Spot.pivot.x + sin(-0.35) * Spot.ropeL, Spot.pivot.y + cos(-0.35) * Spot.ropeL)
            let lx = min(max((ball.x - at.x) / s, 4), 30), ly = min(max((ball.y - at.y) / s, -46), -10)
            return CatPlacement(at: at, depth: 266, dir: 1, pose: .sit, face: Face(eyes: "big", mouth: "open"),
                                armTo: P(lx, ly), wag: 0.5, swish: 1.3)
        case .window:
            return CatPlacement(at: Spot.sill, depth: 238, dir: dir, pose: .sit, face: Face(eyes: happy ? "happy" : "big"), wag: 0.4, swish: 2)
        case .perch:
            return CatPlacement(at: P(Spot.treeX + 6, Spot.treeTop + 3), depth: 250, dir: dir, pose: .lie, face: face, wag: 0.2, swish: 3)
        case .sleep:
            return CatPlacement(at: P(Spot.bed.x + 4, Spot.bed.y + 4), depth: Spot.bed.y + 4, dir: 1, pose: .lie, face: Face(eyes: "closed"), curled: true)
        }
    }
}

// MARK: - Room drawing

enum Room {
    static func paper(_ g: GraphicsContext, size: CGSize) {
        g.fill(Path(CGRect(origin: .zero, size: size)), with: .color(Pal.paper))
        var seed: UInt64 = 0x2545F4914F6CDD1D
        func rnd() -> CGFloat { seed ^= seed << 13; seed ^= seed >> 7; seed ^= seed << 17; return CGFloat(seed % 10_000) / 10_000 }
        var light = Path(), dark = Path()
        for i in 0..<1400 {
            let x = rnd() * size.width, y = rnd() * size.height, a = rnd() * .pi, l = 2 + rnd() * 6
            if i % 2 == 0 { light.move(to: P(x, y)); light.addLine(to: P(x + cos(a) * l, y + sin(a) * l)) }
            else { dark.move(to: P(x, y)); dark.addLine(to: P(x + cos(a) * l, y + sin(a) * l)) }
        }
        g.stroke(light, with: .color(Color.white.opacity(0.7)), lineWidth: 0.6)
        g.stroke(dark, with: .color(Color(hex: 0xCDBEAA, 0.22)), lineWidth: 0.6)
    }

    static func sparkle(_ g: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ r: CGFloat, _ c: Color) {
        var p = Path()
        p.move(to: P(x, y - r)); p.addQuadCurve(to: P(x + r, y), control: P(x, y)); p.addQuadCurve(to: P(x, y + r), control: P(x, y))
        p.addQuadCurve(to: P(x - r, y), control: P(x, y)); p.addQuadCurve(to: P(x, y - r), control: P(x, y))
        g.fill(p, with: .color(c))
    }

    static func cloud(_ g: GraphicsContext, _ x: CGFloat, _ y: CGFloat, _ s: CGFloat) {
        var p = Path()
        p.addPath(ell(x, y, 13 * s, 7 * s)); p.addPath(ell(x - 8 * s, y + 2 * s, 8 * s, 5.5 * s))
        p.addPath(ell(x + 9 * s, y + 2 * s, 8 * s, 5 * s)); p.addPath(ell(x + s, y - 4 * s, 8 * s, 6 * s))
        clay(g, p, x, y, 14 * s, .white, .white, Color(hex: 0xDCE8F2), gloss: 0.4)
    }

    static func background(_ g: GraphicsContext, evening: Bool) {
        let W: CGFloat = 364, H: CGFloat = 382
        paper(g, size: CGSize(width: W, height: H))
        g.fill(Path(CGRect(x: 0, y: 228, width: W, height: H - 228)),
               with: .linearGradient(Gradient(stops: [.init(color: Color(hex: 0xECDECC, 0), location: 0), .init(color: Color(hex: 0xECDECC, 0.75), location: 0.08), .init(color: Color(hex: 0xE2CEB8, 0.9), location: 1)]),
                                     startPoint: P(0, 228), endPoint: P(0, H)))
        g.fill(Path(CGRect(x: 0, y: 236, width: W, height: 16)),
               with: .linearGradient(Gradient(colors: [Color(hex: 0x966E50, 0.12), Color(hex: 0x966E50, 0)]), startPoint: P(0, 236), endPoint: P(0, 252)))
        var beam = Path(); beam.move(to: P(40, 244)); beam.addLine(to: P(146, 244)); beam.addLine(to: P(210, 312)); beam.addLine(to: P(96, 312)); beam.closeSubpath()
        g.fill(beam, with: .color(evening ? Color(hex: 0xBEC8FF, 0.10) : Color(hex: 0xFFF8E1, 0.55)))
        // rug
        clay(g, ell(196, 322, 118, 34), 196, 316, 118, Color(hex: 0xF9D3D8), Color(hex: 0xFFF0F2), Color(hex: 0xEDB6BE), gloss: 0.25)
        g.stroke(ell(196, 322, 100, 27), with: .color(Color.white.opacity(0.75)), style: StrokeStyle(lineWidth: 1.6, dash: [4, 5]))
        for (x, y, c) in [(160.0, 52.0, 0xFFD66B), (200, 190, 0xF7A2B1), (338, 196, 0x9DCBF2), (18, 214, 0xFFD66B), (240, 222, 0x9DCBF2), (150, 110, 0xF7A2B1), (346, 116, 0xFFD66B)] as [(CGFloat, CGFloat, UInt32)] {
            sparkle(g, x, y, 5, Color(hex: c, 0.85))
        }
        window(g, evening: evening)
        shelf(g)
        fish(g)
        clockFace(g)
        tower(g)
    }

    static func window(_ g: GraphicsContext, evening: Bool) {
        clay(g, rrect(22, 52, 120, 116, 14), 82, 110, 70, Color(hex: 0xBFE3D3), Color(hex: 0xE3F5EC), Color(hex: 0x9CCDB8), gloss: 0.25)
        var w = g
        w.clip(to: rrect(32, 62, 100, 96, 9))
        w.fill(Path(CGRect(x: 32, y: 62, width: 100, height: 96)), with: .linearGradient(
            Gradient(colors: evening ? [Color(hex: 0x3B3F7A), Color(hex: 0x6D64A8)] : [Color(hex: 0xBFE2FA), Color(hex: 0xEAF6FE)]),
            startPoint: P(0, 62), endPoint: P(0, 158)))
        if evening {
            clay(w, ell(108, 84, 10, 10), 108, 84, 10, Color(hex: 0xFFF2B8), Color(hex: 0xFFFBE6), Color(hex: 0xF1D97E), gloss: 0.4)
            for (x, y) in [(48.0, 78.0), (66, 100), (86, 72), (56, 134), (98, 126), (120, 142)] as [(CGFloat, CGFloat)] { sparkle(w, x, y, 3, Color(hex: 0xFFF6C8)) }
        } else {
            clay(w, ell(110, 84, 11, 11), 110, 84, 11, Color(hex: 0xFFD66B), Color(hex: 0xFFF1B8), Color(hex: 0xF5B947), gloss: 0.4)
            cloud(w, 60, 114, 0.8)
            var hill = Path(); hill.addPath(ell(46, 160, 26, 20)); hill.addPath(ell(70, 166, 18, 15))
            clay(w, hill, 52, 156, 26, Color(hex: 0xA7D9A2), Color(hex: 0xD6F0D2), Color(hex: 0x86C182), gloss: 0.25)
        }
        clay(g, rrect(80, 62, 4, 96, 2), 82, 110, 30, Color(hex: 0xD5EEE3), .white, Color(hex: 0xB3DAC9), gloss: 0.2)
        clay(g, rrect(32, 108, 100, 4, 2), 82, 110, 30, Color(hex: 0xD5EEE3), .white, Color(hex: 0xB3DAC9), gloss: 0.2)
        clay(g, rrect(12, 164, 140, 11, 5.5), 82, 168, 60, Color(hex: 0xFFF3E4), .white, Color(hex: 0xE7D6C0), gloss: 0.4)
    }

    static func shelf(_ g: GraphicsContext) {
        clay(g, rrect(234, 126, 110, 9, 4.5), 289, 130, 50, Color(hex: 0xF4C7A1), Color(hex: 0xFFE6D2), Color(hex: 0xDDA57C), gloss: 0.3)
        var pot = Path(); pot.move(to: P(250, 106)); pot.addLine(to: P(274, 106)); pot.addQuadCurve(to: P(266, 126), control: P(272, 126))
        pot.addLine(to: P(258, 126)); pot.addQuadCurve(to: P(250, 106), control: P(252, 126))
        clay(g, pot, 262, 114, 14, Color(hex: 0xF7B6A0), Color(hex: 0xFFDCD0), Color(hex: 0xE39780), gloss: 0.3)
        for i in 0..<5 {
            let a = -2.5 + CGFloat(i) * 0.5, lx = 262 + cos(a) * 10, ly = 104 + sin(a) * 10
            clay(g, ell(lx, ly, 9, 4.4, a), lx, ly, 9, Color(hex: 0x9BD49A), Color(hex: 0xD2F0CF), Color(hex: 0x73B771), gloss: 0.3)
        }
        var x: CGFloat = 300
        for (c, w, h) in [(0xB9D2F5, 8.0, 22.0), (0xFFE08A, 7, 18), (0xF7B3C2, 9, 24), (0xBFE3D3, 7, 20)] as [(UInt32, CGFloat, CGFloat)] {
            clay(g, rrect(x, 126 - h, w, h, 2.5), x + w / 2, 126 - h / 2, h * 0.6, Color(hex: c), .white, Color(hex: c), gloss: 0.35)
            x += w + 1.5
        }
    }

    static func fish(_ g0: GraphicsContext) {
        var g = g0
        g.translateBy(x: 226, y: 58)
        var s = Path(); s.move(to: P(0, 0)); s.addLine(to: P(0, 16))
        g.stroke(s, with: .color(Color(hex: 0x8C6E5A, 0.6)), lineWidth: 0.8)
        var f = Path(); f.addPath(ell(0, 28, 15, 9)); f.move(to: P(12, 28)); f.addLine(to: P(24, 20)); f.addLine(to: P(24, 36)); f.closeSubpath()
        clay(g, f, 2, 28, 16, Color(hex: 0xA9D2F4), Color(hex: 0xE1F1FF), Color(hex: 0x7FB4E0), gloss: 0.35)
        g.fill(ell(-7, 26, 1.8, 1.8), with: .color(Color(hex: 0x2B2120)))
        g.fill(ell(-7.5, 25.4, 0.6, 0.6), with: .color(.white))
        g.fill(ell(-6, 31, 2.6, 1.6), with: .color(Color(hex: 0xFF96AA, 0.6)))
        clay(g, ell(0, 0, 2.6, 2.6), 0, 0, 2.6, Pal.pink, Color(hex: 0xFFD6DE), Color(hex: 0xE07F92), gloss: 0.4)
    }

    static func clockFace(_ g: GraphicsContext) {
        let cx: CGFloat = 306, cy: CGFloat = 64
        clay(g, ell(cx, cy, 24, 24), cx, cy, 24, Color(hex: 0xF9C0CB), Color(hex: 0xFFE6EB), Color(hex: 0xE89AAA), gloss: 0.35)
        clay(g, ell(cx, cy, 18.5, 18.5), cx, cy, 18.5, Color(hex: 0xFFF8F0), .white, Color(hex: 0xEDE1D3), gloss: 0.3)
        for i in 0..<12 {
            let a = CGFloat(i) * .pi / 6, r: CGFloat = i % 3 == 0 ? 1.7 : 1
            g.fill(ell(cx + sin(a) * 14.5, cy - cos(a) * 14.5, r, r), with: .color(Color(hex: 0xE3B8C0)))
        }
    }

    static func tower(_ g: GraphicsContext) {
        let x = Spot.treeX
        clay(g, rrect(x - 44, 240, 88, 14, 7), x, 246, 44, Color(hex: 0xF3E6D6), Color(hex: 0xFFFAF3), Color(hex: 0xDCC8AE), gloss: 0.35)
        for s: CGFloat in [-1, 1] {
            let ex = x - 22 + s * 10
            var ear = Path(); ear.move(to: P(ex - 5, 214)); ear.addQuadCurve(to: P(x - 22 + s * 13, 203), control: P(x - 22 + s * 12, 200))
            ear.addQuadCurve(to: P(ex + 5, 214), control: P(x - 22 + s * 15, 208)); ear.closeSubpath()
            clay(g, ear, x - 22 + s * 11, 208, 7, Color(hex: 0xCDBEF2), Color(hex: 0xEFE9FF), Color(hex: 0xA895E0), gloss: 0.3)
        }
        clay(g, rrect(x - 42, 212, 40, 30, 10), x - 22, 226, 24, Color(hex: 0xD7CCF4), Color(hex: 0xF2EDFF), Color(hex: 0xB3A3E4), gloss: 0.35)
        clay(g, ell(x - 22, 230, 9.5, 10), x - 22, 230, 10, Color(hex: 0x6D5D93), Color(hex: 0x8C7CB3), Color(hex: 0x4E4170), gloss: 0)
        for (px, top) in [(x + 6, Spot.treeTop + 4), (x + 30, Spot.treeLow + 6)] {
            clay(g, rrect(px - 7, top, 14, 242 - top, 6), px, (top + 242) / 2, 24, Color(hex: 0xEBCD9E), Color(hex: 0xFBEBCF), Color(hex: 0xD2AD7B), gloss: 0.25)
            var rope = Path()
            var y = top + 6
            while y < 238 { rope.move(to: P(px - 6, y)); rope.addLine(to: P(px + 6, y + 1.3)); y += 3.6 }
            g.stroke(rope, with: .color(Color(hex: 0xA57D4B, 0.28)), lineWidth: 1)
        }
        clay(g, rrect(x - 26, Spot.treeLow - 2, 66, 11, 5.5), x + 7, Spot.treeLow + 2, 34, Color(hex: 0xFBD3BF), Color(hex: 0xFFEDE3), Color(hex: 0xEDB49A), gloss: 0.35)
        clay(g, ell(x + 6, Spot.treeTop + 4, 25, 9), x + 6, Spot.treeTop + 2, 25, Color(hex: 0xF7B8C6), Color(hex: 0xFFE2E9), Color(hex: 0xE48FA4), gloss: 0.35)
        g.fill(ell(x + 6, Spot.treeTop + 2, 18, 5), with: .color(Color(hex: 0xFFE8EE)))
    }

    // floor objects, split into back/front halves so Taro's face can go into bowls
    static func bowlShape(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ depth: CGFloat) -> Path {
        var p = Path()
        p.addArc(center: P(x, y - 3), radius: rx, startAngle: .zero, endAngle: .degrees(180), clockwise: false,
                 transform: CGAffineTransform(translationX: x, y: y - 3).scaledBy(x: 1, y: 0.27).translatedBy(x: -x, y: -(y - 3)))
        p.addQuadCurve(to: P(x - rx * 0.55, y + depth), control: P(x - rx + 2, y + depth))
        p.addLine(to: P(x + rx * 0.55, y + depth))
        p.addQuadCurve(to: P(x + rx, y - 3), control: P(x + rx - 2, y + depth))
        p.closeSubpath()
        return p
    }
    static func foodBack(_ g: GraphicsContext, food: CGFloat) {
        let x = Spot.bowl.x, y = Spot.bowl.y
        g.fill(ell(x, y + 9, 26, 6.5), with: .color(Color(hex: 0x785032, 0.16)))
        clay(g, ell(x, y - 3, 22, 6.5), x, y - 4, 22, Color(hex: 0xFFB3B3), Color(hex: 0xFFE3E3), Color(hex: 0xF08F8F), gloss: 0.3)
        g.fill(ell(x, y - 2.5, 18, 4.6), with: .color(Color(hex: 0xE98A8A)))
        if food > 0.02 {
            let h = 1.5 + food * 5
            clay(g, ell(x, y - 2.5, 15 * min(1, 0.55 + food * 0.5), h), x, y - 3, 15, Color(hex: 0xC98B5A), Color(hex: 0xEBB88A), Color(hex: 0xA86C3F), gloss: 0.25)
            for i in 0..<Int(9 * food) {
                let kx = x - 11 + CGFloat((i * 73) % 220) / 10, ky = y - 3 - CGFloat(i % 3) * h / 3
                clay(g, ell(kx, ky, 2.2, 1.7), kx, ky, 2.2, Color(hex: 0xD99E6B), Color(hex: 0xF6CFA6), Color(hex: 0xB97D4C), gloss: 0.3, shadow: false)
            }
        }
    }
    static func foodFront(_ g: GraphicsContext) {
        let x = Spot.bowl.x, y = Spot.bowl.y
        clay(g, bowlShape(x, y, 22, 11), x, y + 2, 22, Color(hex: 0xFF9E9E), Color(hex: 0xFFD3D3), Color(hex: 0xE57A7A), gloss: 0.35)
        g.draw(Text("TARO").font(.system(size: 6, weight: .bold, design: .rounded)).foregroundColor(.white), at: P(x, y + 5))
    }
    static func waterBack(_ g: GraphicsContext) {
        let x = Spot.water.x, y = Spot.water.y
        g.fill(ell(x, y + 8, 22, 6), with: .color(Color(hex: 0x785032, 0.16)))
        clay(g, ell(x, y - 3, 18, 5.5), x, y - 4, 18, Color(hex: 0xBFE3F7), Color(hex: 0xEAF7FF), Color(hex: 0x94CBEA), gloss: 0.3)
        g.fill(ell(x, y - 2.5, 14.5, 3.8), with: .radialGradient(Gradient(colors: [Color(hex: 0xF2FBFF), Color(hex: 0x9FD6F0)]), center: P(x - 4, y - 4), startRadius: 1, endRadius: 16))
    }
    static func waterFront(_ g: GraphicsContext) {
        let x = Spot.water.x, y = Spot.water.y
        clay(g, bowlShape(x, y, 18, 10), x, y + 2, 18, Color(hex: 0xA9D8F3), Color(hex: 0xE3F4FF), Color(hex: 0x7DBCE2), gloss: 0.35)
        sparkle(g, x, y + 4, 2.6, Color.white.opacity(0.9))
    }
    static func bedBack(_ g: GraphicsContext) {
        let b = Spot.bed
        clay(g, ell(b.x, b.y, 56, 22), b.x, b.y - 6, 56, Color(hex: 0xCDBEF2), Color(hex: 0xEFE9FF), Color(hex: 0xA895E0), gloss: 0.3)
        clay(g, ell(b.x, b.y + 1, 42, 13), b.x, b.y - 2, 42, Color(hex: 0xEDE6FF), .white, Color(hex: 0xD3C6F5), gloss: 0.3)
    }
    static func bedFront(_ g: GraphicsContext) {
        let b = Spot.bed
        var p = Path()
        p.addArc(center: b, radius: 56, startAngle: .zero, endAngle: .degrees(180), clockwise: false,
                 transform: CGAffineTransform(translationX: b.x, y: b.y).scaledBy(x: 1, y: 22.0 / 56).translatedBy(x: -b.x, y: -b.y))
        p.addArc(center: P(b.x, b.y + 1), radius: 42, startAngle: .degrees(180), endAngle: .zero, clockwise: true,
                 transform: CGAffineTransform(translationX: b.x, y: b.y + 1).scaledBy(x: 1, y: 13.0 / 42).translatedBy(x: -b.x, y: -(b.y + 1)))
        p.closeSubpath()
        clay(g, p, b.x, b.y + 6, 56, Color(hex: 0xC6B5EE), Color(hex: 0xE9E1FF), Color(hex: 0x9F8BD8), gloss: 0.25)
    }
    static func yarnBall(_ g: GraphicsContext, at c: CGPoint, r: CGFloat) {
        var t = Path(); t.move(to: P(c.x - r * 0.5, c.y)); t.addCurve(to: P(c.x - 34, c.y + 6), control1: P(c.x - 12, c.y + 8), control2: P(c.x - 24, c.y - 2))
        g.stroke(t, with: .color(Color(hex: 0x8DB9EC)), style: StrokeStyle(lineWidth: 1.8, lineCap: .round))
        g.fill(ell(c.x, c.y + 1, r * 1.05, r * 0.3), with: .color(Color(hex: 0x785032, 0.2)))
    }
}

// MARK: - Live bits

/// The yarn ball itself (spins while Taro plays).
struct YarnBallView: View {
    var body: some View {
        Canvas { ctx, size in
            let c = P(size.width / 2, size.height / 2), r = size.width / 2 - 1
            clay(ctx, ell(c.x, c.y, r, r), c.x, c.y, r, Color(hex: 0x9DC6F2), Color(hex: 0xE2F0FF), Color(hex: 0x6E9FDA), gloss: 0.4)
            var g = ctx; g.clip(to: ell(c.x, c.y, r, r))
            for i in 0..<4 { g.stroke(ell(c.x, c.y, r, r * 0.35, CGFloat(i) * 0.8), with: .color(Color(hex: 0x5A82C8, 0.45)), lineWidth: 1.2) }
        }
    }
}

/// The pom-pom swinging on its string under the cat tower.
struct PomPomView: View {
    var amplitude: CGFloat
    static let size = CGSize(width: 90, height: 48)
    var body: some View {
        FrameLoop(count: 16, period: 1.6, size: Self.size) { i in
            Canvas { ctx, _ in
                let a = amplitude * sin(CGFloat(i) / 16 * 2 * .pi)
                let pv = P(45, 2), b = P(45 + sin(a) * Spot.ropeL, 2 + cos(a) * Spot.ropeL)
                var s = Path(); s.move(to: pv); s.addLine(to: b)
                ctx.stroke(s, with: .color(Color(hex: 0x96735F, 0.75)), lineWidth: 0.9)
                clay(ctx, ell(b.x, b.y, 5.5, 5.5), b.x, b.y, 5.5, Color(hex: 0xFFE27A), Color(hex: 0xFFF6CC), Color(hex: 0xF2C53D), gloss: 0.45)
            }
        }
    }
}

struct FloatingHearts: View {
    var body: some View {
        FrameLoop(count: 14, period: 2.1, size: CGSize(width: 50, height: 60)) { i in
            let p = CGFloat(i) / 14, q = (p + 0.5).truncatingRemainder(dividingBy: 1)
            ZStack {
                Text("♥").font(.system(size: 15)).foregroundStyle(Color(hex: 0xF2668C).opacity(Double(1 - p)))
                    .offset(x: -6 + 6 * sin(p * 2 * .pi), y: 22 - 44 * p)
                Text("♥").font(.system(size: 11)).foregroundStyle(Color(hex: 0xF2668C).opacity(Double(1 - q)))
                    .offset(x: 10 + 5 * sin(q * 2 * .pi), y: 22 - 44 * q)
            }
        }
    }
}

struct SleepyZs: View {
    var body: some View {
        FrameLoop(count: 15, period: 3, size: CGSize(width: 44, height: 44)) { i in
            let p = CGFloat(i) / 15, q = (p + 0.5).truncatingRemainder(dividingBy: 1)
            ZStack {
                Text("z").font(.system(size: 11 + 5 * p, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8A80D8).opacity(Double(1 - p))).offset(x: -8 + 10 * p, y: 14 - 26 * p)
                Text("z").font(.system(size: 11 + 5 * q, weight: .heavy, design: .rounded))
                    .foregroundStyle(Color(hex: 0x8A80D8).opacity(Double(1 - q))).offset(x: -8 + 10 * q, y: 14 - 26 * q)
            }
        }
    }
}

struct WallClockHands: View {
    var body: some View {
        ZStack {
            hand(8.5, 2.8, Color(hex: 0x7B5B55)).clockHand(.hour)
            hand(12.5, 2, Color(hex: 0x7B5B55)).clockHand(.minute)
            hand(13.5, 1, Color(hex: 0xF08AA0)).clockHand(.second)
            Circle().fill(Color(hex: 0xF08AA0)).frame(width: 4.8, height: 4.8)
        }
        .frame(width: 30, height: 30)
    }
    private func hand(_ len: CGFloat, _ w: CGFloat, _ c: Color) -> some View {
        VStack(spacing: 0) {
            Capsule().fill(c).frame(width: w, height: len)
            Color.clear.frame(width: w, height: len)
        }
        .frame(width: 30, height: 30)
    }
}

struct StatsBar: View {
    let state: CatState
    var body: some View {
        HStack(spacing: 9) {
            Text(CatInfo.name).font(.system(size: 14, weight: .bold, design: .rounded)).foregroundStyle(Pal.ink)
            meter("food", state.fullness, Color(hex: 0xF6A87C))
            meter("fun", state.fun, Color(hex: 0x8DB9EC))
            meter("energy", state.energy, Color(hex: 0xF3CF63))
            Text("♥ \(state.hearts)").font(.system(size: 12, weight: .bold, design: .rounded)).foregroundStyle(Color(hex: 0xE65973))
        }
        .padding(.horizontal, 12).padding(.vertical, 6)
        .background(Capsule().fill(Color.white).shadow(color: Color(hex: 0x5A3C28, 0.15), radius: 2, y: 1.5))
    }
    private func meter(_ n: String, _ v: Double, _ c: Color) -> some View {
        HStack(spacing: 4) {
            Text(n).font(.system(size: 10.5, weight: .medium, design: .rounded)).foregroundStyle(Color(hex: 0x7A675C))
            ZStack(alignment: .leading) {
                Capsule().fill(Color.black.opacity(0.08)).frame(width: 30, height: 7)
                Capsule().fill(c).frame(width: max(3, 30 * v / 100), height: 7)
            }
        }
    }
}

// MARK: - The large widget: Taro's room

struct RoomView: View {
    let state: CatState
    let date: Date
    static let size = CGSize(width: 364, height: 382)

    var body: some View {
        let scene = state.scene(at: date)
        let cat = CatPlacement.make(scene, state: state, date: date)
        let evening = CatState.isEvening(date)
        let fed = scene == .eat ? 1.0 : 0.25
        // floor things in front-to-back order; anything "in front" of Taro is drawn after him
        let items: [(CGFloat, (GraphicsContext) -> Void)] = [
            (Spot.bed.y - 14, { Room.bedBack($0) }), (Spot.bed.y + 14, { Room.bedFront($0) }),
            (Spot.bowl.y - 6, { Room.foodBack($0, food: fed) }), (Spot.bowl.y + 4, { Room.foodFront($0) }),
            (Spot.water.y - 6, { Room.waterBack($0) }), (Spot.water.y + 4, { Room.waterFront($0) }),
        ]
        let catY = (scene == .window || scene == .perch) ? -1 : cat.at.y
        let yarnAt = Spot.yarn, yarnR = 10 * depthScale(Spot.yarn.y)

        ZStack(alignment: .topLeading) {
            Canvas { ctx, _ in Room.background(ctx, evening: evening) }
            WallClockHands().position(x: 306, y: 64)
            PomPomView(amplitude: scene == .pompom ? 0.6 : 0.12)
                .position(x: Spot.pivot.x, y: Spot.pivot.y - 2 + PomPomView.size.height / 2)

            Canvas { ctx, _ in for (y, draw) in items where y < catY { draw(ctx) } }

            if scene != .yarn {
                Canvas { ctx, _ in Room.yarnBall(ctx, at: yarnAt, r: yarnR) }
                YarnBallView().frame(width: yarnR * 2, height: yarnR * 2).position(x: yarnAt.x, y: yarnAt.y - yarnR)
            }

            CatFigure(pose: cat.pose, face: cat.face, armTo: cat.armTo, curled: cat.curled, wag: cat.wag, swishPeriod: cat.swish)
                .placed(at: cat.at, dir: cat.dir, scale: cat.scale)

            Canvas { ctx, _ in for (y, draw) in items where y >= catY { draw(ctx) } }

            if scene == .yarn {
                Canvas { ctx, _ in Room.yarnBall(ctx, at: yarnAt, r: yarnR) }
                YarnBallView().frame(width: yarnR * 2, height: yarnR * 2)
                    .spinForever(period: 1.2)
                    .position(x: yarnAt.x, y: yarnAt.y - yarnR)
            }

            if state.reaction == .petted || state.reaction == .purr {
                FloatingHearts().position(x: cat.at.x + 16, y: cat.at.y - 58 * cat.scale)
            }
            if scene == .sleep { SleepyZs().position(x: cat.at.x + 14, y: cat.at.y - 40) }

            if evening {
                Color(hex: 0x3C3778, 0.26).allowsHitTesting(false)
            }

            if let msg = state.message(at: date) {
                Bubble(text: msg)
                    .position(x: min(max(cat.at.x, 70), 294), y: max(58, cat.at.y - (scene == .sleep ? 50 : 76) * cat.scale))
            }

            StatsBar(state: state).position(x: 182, y: 24)

            // tap areas
            tap(PetCatIntent(), x: cat.at.x, y: cat.at.y - 26 * cat.scale, w: 56 * cat.scale, h: 60 * cat.scale)
            tap(FeedCatIntent(), x: Spot.bowl.x, y: Spot.bowl.y, w: 50, h: 28)
            tap(DrinkIntent(), x: Spot.water.x, y: Spot.water.y, w: 42, h: 26)
            tap(PlayWithCatIntent(), x: yarnAt.x, y: yarnAt.y - yarnR, w: 40, h: 34)
            tap(PomPomIntent(), x: Spot.pivot.x, y: Spot.pivot.y + Spot.ropeL, w: 34, h: 34)
            tap(WindowIntent(), x: 82, y: 110, w: 120, h: 110)
            tap(ToggleSleepIntent(), x: Spot.bed.x - 34, y: Spot.bed.y + 4, w: 44, h: 40)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }

    private func tap<I: AppIntent>(_ intent: I, x: CGFloat, y: CGFloat, w: CGFloat, h: CGFloat) -> some View {
        Button(intent: intent) {
            Color.white.opacity(0.001).frame(width: w, height: h)
        }
        .buttonStyle(.plain)
        .position(x: x, y: y)
    }
}

// MARK: - The small widget: just Taro

struct SmallCatView: View {
    let state: CatState
    let date: Date
    static let size = CGSize(width: 170, height: 170)

    var body: some View {
        let sleeping = state.isSleeping
        let happy = state.reaction == .petted
        ZStack(alignment: .topLeading) {
            Canvas { ctx, size in
                Room.paper(ctx, size: size)
                ctx.fill(Path(CGRect(x: 0, y: 112, width: 170, height: 58)), with: .linearGradient(
                    Gradient(colors: [Color(hex: 0xECDECC, 0.8), Color(hex: 0xE2CEB8, 0.95)]), startPoint: P(0, 112), endPoint: P(0, 170)))
                clay(ctx, ell(80, 140, 62, 16), 80, 136, 62, Color(hex: 0xF9D3D8), Color(hex: 0xFFF0F2), Color(hex: 0xEDB6BE), gloss: 0.25)
                Room.sparkle(ctx, 22, 70, 5, Color(hex: 0xFFD66B, 0.85))
                Room.sparkle(ctx, 150, 92, 4, Color(hex: 0x9DCBF2, 0.85))
            }
            Text(CatInfo.name).font(.system(size: 13, weight: .bold, design: .rounded)).foregroundStyle(Pal.ink).position(x: 30, y: 16)
            Text("♥ \(state.hearts)").font(.system(size: 11, weight: .bold, design: .rounded)).foregroundStyle(Color(hex: 0xE65973)).position(x: 144, y: 16)
            CatFigure(pose: .sit, face: Face(eyes: sleeping ? "closed" : (happy ? "happy" : "open")), curled: sleeping)
                .placed(at: P(78, 146), dir: 1, scale: 1.3)
            if happy || state.reaction == .purr { FloatingHearts().position(x: 106, y: 66) }
            if let msg = state.message(at: date) { Bubble(text: msg, fontSize: 10.5).position(x: 85, y: 36) }
            Button(intent: PetCatIntent()) { Color.white.opacity(0.001).frame(width: 90, height: 100) }
                .buttonStyle(.plain).position(x: 78, y: 100)
            Button(intent: FeedCatIntent()) {
                Canvas { ctx, _ in
                    var p = Path(); p.move(to: P(4, 12)); p.addLine(to: P(32, 12)); p.addQuadCurve(to: P(25, 24), control: P(31, 24)); p.addLine(to: P(11, 24)); p.addQuadCurve(to: P(4, 12), control: P(5, 24))
                    clay(ctx, ell(18, 12, 14, 4.5), 18, 11, 14, Color(hex: 0xC98B5A), Color(hex: 0xEBB88A), Color(hex: 0xA86C3F))
                    clay(ctx, p, 18, 16, 14, Color(hex: 0xFF9E9E), Color(hex: 0xFFD3D3), Color(hex: 0xE57A7A))
                }
                .frame(width: 36, height: 30)
            }
            .buttonStyle(.plain).position(x: 144, y: 142)
        }
        .frame(width: Self.size.width, height: Self.size.height)
    }
}
