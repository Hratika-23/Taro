import SwiftUI

// Preview stand-in for LiveMotion.swift (used only to render screenshots on a Mac in CI).
enum PreviewFrame { static var index = 3 }

struct FrameLoop<Content: View>: View {
    let count: Int
    let period: TimeInterval
    let size: CGSize
    let content: (Int) -> Content
    init(count: Int, period: TimeInterval, size: CGSize, @ViewBuilder content: @escaping (Int) -> Content) {
        self.count = count; self.period = period; self.size = size; self.content = content
    }
    var body: some View { content(PreviewFrame.index % count).frame(width: size.width, height: size.height) }
}

enum HandKind { case hour, minute, second }

extension View {
    func spinForever(period: TimeInterval, anchor: UnitPoint = .center) -> some View { self.rotationEffect(.degrees(25)) }
    func clockHand(_ kind: HandKind) -> some View {
        let d = Date(), c = Calendar.current
        let h = Double(c.component(.hour, from: d) % 12), m = Double(c.component(.minute, from: d)), s = Double(c.component(.second, from: d))
        switch kind {
        case .hour: return AnyView(rotationEffect(.degrees((h + m / 60) * 30)))
        case .minute: return AnyView(rotationEffect(.degrees(m * 6)))
        case .second: return AnyView(rotationEffect(.degrees(s * 6)))
        }
    }
}
