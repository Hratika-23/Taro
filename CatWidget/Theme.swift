import SwiftUI

// Change the cat's name here.
enum CatInfo {
    static let name = "Taro"
}

extension Color {
    init(hex: UInt32, _ alpha: Double = 1) {
        self.init(.sRGB,
                  red: Double((hex >> 16) & 0xFF) / 255,
                  green: Double((hex >> 8) & 0xFF) / 255,
                  blue: Double(hex & 0xFF) / 255,
                  opacity: alpha)
    }
}

enum Pal {
    static let fur = Color(hex: 0xF6B470), furLight = Color(hex: 0xFFE1BC), furDeep = Color(hex: 0xE4914C)
    static let stripe = Color(hex: 0xEBA05E), cream = Color(hex: 0xFFF6EA), creamShade = Color(hex: 0xEADCC8)
    static let pink = Color(hex: 0xF7A2B1), eye = Color(hex: 0x231B19), ink = Color(hex: 0x3B2D27)
    static let paper = Color(hex: 0xF7F3EE)
}

// MARK: - Path helpers (same coordinates as the web preview)

@inline(__always) func P(_ x: CGFloat, _ y: CGFloat) -> CGPoint { CGPoint(x: x, y: y) }

func ell(_ x: CGFloat, _ y: CGFloat, _ rx: CGFloat, _ ry: CGFloat, _ rot: CGFloat = 0) -> Path {
    Path(ellipseIn: CGRect(x: -rx, y: -ry, width: rx * 2, height: ry * 2))
        .applying(CGAffineTransform(rotationAngle: rot).concatenating(CGAffineTransform(translationX: x, y: y)))
}

func rrect(_ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, _ r: CGFloat) -> Path {
    Path(roundedRect: CGRect(x: x, y: y, width: w, height: max(0.1, h)), cornerRadius: r)
}

/// Depth: things further down the floor are closer, so a bit bigger.
func depthScale(_ d: CGFloat) -> CGFloat { 0.80 + (d - 236) / (382 - 236) * 0.42 }

/// Soft clay look: drop shadow, light from the top-left, darker underside, glossy dab.
func clay(_ g: GraphicsContext, _ path: Path, _ cx: CGFloat, _ cy: CGFloat, _ r: CGFloat,
          _ base: Color, _ light: Color, _ deep: Color, gloss: Double = 0.35, shadow: Bool = true) {
    if shadow {
        var s = g
        s.addFilter(.shadow(color: Color(hex: 0x5A3C28, 0.22), radius: 1.6, x: 0, y: 1.6))
        s.fill(path, with: .color(base))
    }
    g.fill(path, with: .radialGradient(
        Gradient(stops: [.init(color: light, location: 0), .init(color: base, location: 0.55), .init(color: deep, location: 1)]),
        center: P(cx - r * 0.35, cy - r * 0.45), startRadius: r * 0.05, endRadius: r * 1.25))
    if gloss > 0 {
        var c = g
        c.clip(to: path)
        c.fill(ell(cx - r * 0.4, cy - r * 0.55, r * 0.5, r * 0.5),
               with: .radialGradient(Gradient(colors: [Color.white.opacity(gloss), Color.white.opacity(0)]),
                                     center: P(cx - r * 0.4, cy - r * 0.55), startRadius: 0, endRadius: r * 0.5))
    }
}

/// Fits a fixed-size design into the widget's real size.
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

struct Bubble: View {
    let text: String
    var fontSize: CGFloat = 12.5

    var body: some View {
        Text(text)
            .font(.system(size: fontSize, weight: .semibold, design: .rounded))
            .foregroundStyle(Pal.ink)
            .padding(.horizontal, 10)
            .padding(.vertical, 5)
            .background(
                Capsule().fill(Color.white)
                    .shadow(color: Color(hex: 0x5A3C28, 0.15), radius: 2, y: 1.5)
            )
            .fixedSize()
    }
}
