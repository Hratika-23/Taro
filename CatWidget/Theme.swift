import SwiftUI

// Change the cat's name here.
enum CatInfo {
    static let name = "Taro"
}

extension Color {
    // Cat
    static let fur       = Color(red: 0.96, green: 0.63, blue: 0.32)
    static let furDark   = Color(red: 0.84, green: 0.47, blue: 0.20)
    static let cream     = Color(red: 1.00, green: 0.93, blue: 0.82)
    static let catPink   = Color(red: 0.97, green: 0.60, blue: 0.66)
    static let ink       = Color(red: 0.22, green: 0.17, blue: 0.15)
    // Room
    static let wall      = Color(red: 0.98, green: 0.88, blue: 0.76)
    static let wallDot   = Color(red: 0.95, green: 0.81, blue: 0.67)
    static let floorWood = Color(red: 0.80, green: 0.56, blue: 0.36)
    static let floorLine = Color(red: 0.71, green: 0.48, blue: 0.29)
    static let baseboard = Color(red: 0.97, green: 0.95, blue: 0.91)
    static let bedRim    = Color(red: 0.62, green: 0.55, blue: 0.86)
    static let bedInner  = Color(red: 0.81, green: 0.76, blue: 0.97)
    static let bowlRed   = Color(red: 0.90, green: 0.34, blue: 0.34)
    static let kibble    = Color(red: 0.62, green: 0.38, blue: 0.20)
    static let yarn      = Color(red: 0.36, green: 0.62, blue: 0.93)
    static let yarnDark  = Color(red: 0.22, green: 0.44, blue: 0.75)
    static let curtain   = Color(red: 0.55, green: 0.78, blue: 0.70)
    static let frameWood = Color(red: 0.66, green: 0.45, blue: 0.28)
    static let zzz       = Color(red: 0.40, green: 0.36, blue: 0.72)
}

// MARK: - Little shapes

struct Triangle: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.midX, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// "^" shape — happy closed eyes.
struct ArcUp: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.maxY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.maxY),
                       control: CGPoint(x: r.midX, y: r.minY - r.height * 0.8))
        return p
    }
}

/// "‿" shape — sleeping / blinking eyes.
struct ArcDown: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.midX, y: r.maxY + r.height * 0.8))
        return p
    }
}

/// Cat mouth "w".
struct MouthShape: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX, y: r.minY))
        p.addQuadCurve(to: CGPoint(x: r.midX, y: r.minY),
                       control: CGPoint(x: r.minX + r.width * 0.25, y: r.maxY + 2))
        p.addQuadCurve(to: CGPoint(x: r.maxX, y: r.minY),
                       control: CGPoint(x: r.minX + r.width * 0.75, y: r.maxY + 2))
        return p
    }
}

struct Trapezoid: Shape {
    func path(in r: CGRect) -> Path {
        var p = Path()
        p.move(to: CGPoint(x: r.minX + r.width * 0.22, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX - r.width * 0.22, y: r.minY))
        p.addLine(to: CGPoint(x: r.maxX, y: r.maxY))
        p.addLine(to: CGPoint(x: r.minX, y: r.maxY))
        p.closeSubpath()
        return p
    }
}

/// Fits a fixed-size design into whatever size the widget really is.
struct Scaled<Content: View>: View {
    let design: CGSize
    let content: Content

    init(_ design: CGSize, @ViewBuilder content: () -> Content) {
        self.design = design
        self.content = content()
    }

    var body: some View {
        GeometryReader { geo in
            let s = max(geo.size.width / design.width, geo.size.height / design.height)
            content
                .frame(width: design.width, height: design.height)
                .scaleEffect(s)
                .frame(width: geo.size.width, height: geo.size.height)
        }
        .clipped()
    }
}
