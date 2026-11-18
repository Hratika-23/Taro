import SwiftUI
import AppKit

@main
struct Render {
    @MainActor static func save<V: View>(_ v: V, _ size: CGSize, _ path: String) {
        let r = ImageRenderer(content: v.frame(width: size.width, height: size.height))
        r.scale = 2
        guard let cg = r.cgImage else { print("render failed", path); return }
        let rep = NSBitmapImageRep(cgImage: cg)
        try? rep.representation(using: .png, properties: [:])?.write(to: URL(fileURLWithPath: path))
        print("wrote", path)
    }

    @MainActor static func main() {
        let out = CommandLine.arguments.count > 1 ? CommandLine.arguments[1] : "out"
        var day = DateComponents(); day.year = 2026; day.month = 11; day.day = 18; day.hour = 15; day.minute = 5
        let afternoon = Calendar.current.date(from: day)!
        day.hour = 21
        let evening = Calendar.current.date(from: day)!
        for scene in CatScene.allCases {
            var s = CatState()
            s.updatedAt = afternoon; s.hearts = 7
            if scene == .sleep { s.isSleeping = true } else { s.activity = scene; s.activityUntil = afternoon.addingTimeInterval(60) }
            save(RoomView(state: s, date: afternoon), RoomView.size, "\(out)/room_\(scene.rawValue).png")
        }
        var pet = CatState(); pet.updatedAt = afternoon; pet.activity = .sit; pet.activityUntil = afternoon.addingTimeInterval(60)
        pet.reaction = .petted; pet.reactionUntil = afternoon.addingTimeInterval(8)
        save(RoomView(state: pet, date: afternoon), RoomView.size, "\(out)/room_petted.png")
        var night = CatState(); night.updatedAt = evening; night.activity = .window; night.activityUntil = evening.addingTimeInterval(60)
        save(RoomView(state: night, date: evening), RoomView.size, "\(out)/room_evening.png")
        save(SmallCatView(state: pet, date: afternoon), SmallCatView.size, "\(out)/small.png")
    }
}
