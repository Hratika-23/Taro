import Foundation

// MARK: - What Taro can be doing

enum CatScene: String, Codable, CaseIterable {
    case sit, loaf, stretch, eat, drink, yarn, pompom, window, perch, sleep
}

enum CatReaction: String, Codable { case none, petted, purr, full, grumpy, wokeUp, tooTired }

enum CatAction { case pet, feed, drink, yarn, pompom, window, toggleSleep }

struct CatState: Codable, Equatable {
    var fullness: Double = 75
    var fun: Double = 70
    var energy: Double = 85
    var hearts: Int = 0
    var isSleeping = false
    var sleptAt: Date = .distantPast
    var lastInteraction: Date = .distantPast
    var updatedAt = Date()
    var activity: CatScene? = nil
    var activityUntil: Date = .distantPast
    var reaction: CatReaction = .none
    var reactionUntil: Date = .distantPast

    static func isNight(_ d: Date) -> Bool { let h = Calendar.current.component(.hour, from: d); return h >= 23 || h < 7 }
    static func isEvening(_ d: Date) -> Bool { let h = Calendar.current.component(.hour, from: d); return h >= 19 || h < 6 }

    /// Lets time pass (10-minute steps): hunger, boredom, naps.
    func advanced(to date: Date) -> CatState {
        var s = self
        var t = max(s.updatedAt, date.addingTimeInterval(-14 * 86400))
        while t < date {
            let next = min(date, t.addingTimeInterval(600)), h = next.timeIntervalSince(t) / 3600
            s.fullness = max(0, s.fullness - h * 6)
            if s.isSleeping {
                s.fun = max(0, s.fun - h * 1.5); s.energy = min(100, s.energy + h * 22)
                if s.energy >= 95, next.timeIntervalSince(s.sleptAt) > 45 * 60, !Self.isNight(next) { s.isSleeping = false }
            } else {
                s.fun = max(0, s.fun - h * 7); s.energy = max(0, s.energy - h * 5)
                let idle = next.timeIntervalSince(s.lastInteraction) > 20 * 60
                if s.energy <= 8 || (Self.isNight(next) && idle) { s.isSleeping = true; s.sleptAt = next }
            }
            t = next
        }
        if date > s.updatedAt { s.updatedAt = date }
        if date >= s.reactionUntil { s.reaction = .none }
        if date >= s.activityUntil { s.activity = nil }
        return s
    }

    private mutating func act(_ a: CatScene, _ now: Date, _ secs: TimeInterval) { activity = a; activityUntil = now.addingTimeInterval(secs) }
    private mutating func react(_ r: CatReaction, _ now: Date, _ secs: TimeInterval) { reaction = r; reactionUntil = now.addingTimeInterval(secs) }

    mutating func apply(_ action: CatAction, at now: Date) {
        self = advanced(to: now)
        lastInteraction = now
        switch action {
        case .pet:
            hearts += 1; fun = min(100, fun + 6)
            react(isSleeping ? .purr : .petted, now, 8)
        case .feed:
            if fullness >= 92 { react(.full, now, 6); return }
            isSleeping = false; fullness = min(100, fullness + 35); act(.eat, now, 40)
        case .drink:
            isSleeping = false; act(.drink, now, 30)
        case .yarn, .pompom:
            if isSleeping { isSleeping = false; react(.grumpy, now, 6); return }
            if energy < 15 { react(.tooTired, now, 6); return }
            fun = min(100, fun + 22); energy = max(0, energy - 6)
            act(action == .yarn ? .yarn : .pompom, now, 45)
        case .window:
            isSleeping = false; fun = min(100, fun + 8); act(.window, now, 180)
        case .toggleSleep:
            if isSleeping { isSleeping = false; react(.wokeUp, now, 6); act(.stretch, now, 20) }
            else { isSleeping = true; sleptAt = now; activity = nil }
        }
    }

    // MARK: What the widget shows

    var mood: String {
        if fullness < 25 { return "hungry" }
        if energy < 20 { return "tired" }
        if fun < 25 { return "bored" }
        return "ok"
    }

    /// The scene at a moment in time. When you're not playing with him,
    /// Taro picks something new to do every 10 minutes.
    func scene(at date: Date) -> CatScene {
        if isSleeping { return .sleep }
        if let a = activity, date < activityUntil { return a }
        let slot = Int(date.timeIntervalSince1970 / 600)
        var r = UInt64(truncatingIfNeeded: slot) &* 0x9E3779B97F4A7C15
        r ^= r >> 29
        let options: [(CatScene, Int)] = [(.sit, 4), (.loaf, 3), (.window, 3), (.perch, 2), (.pompom, 2), (.stretch, 1), (.yarn, fun < 40 ? 3 : 1)]
        var n = Int(r % UInt64(options.reduce(0) { $0 + $1.1 }))
        for (s, w) in options { if n < w { return s }; n -= w }
        return .sit
    }

    /// Facing right (1) or left (-1), varying so he doesn't look frozen.
    func facing(at date: Date) -> Double {
        Int(date.timeIntervalSince1970 / 600) % 3 == 0 ? -1 : 1
    }

    func message(at date: Date) -> String? {
        switch reaction {
        case .petted: return "Purrrr… ♥"
        case .purr: return "mrrp… zzz"
        case .full: return "I'm full, thanks!"
        case .grumpy: return "Hey! I was napping"
        case .wokeUp: return "Mrrow? I'm up!"
        case .tooTired: return "Too sleepy to play…"
        case .none: break
        }
        switch scene(at: date) {
        case .eat: return "Nom nom nom!"
        case .pompom: return "Swat swat!"
        case .yarn: return "Gotcha, yarn!"
        case .window: return "Birds!"
        case .sleep: return nil
        default: break
        }
        switch mood {
        case "hungry": return "I'm hungry…"
        case "bored": return "Play with me!"
        case "tired": return "So sleepy…"
        default: return nil
        }
    }
}

// MARK: - Saving

enum CatStore {
    private static let key = "taro.state.v2"

    static func load(at date: Date = Date()) -> CatState {
        var saved = CatState()
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(CatState.self, from: data) { saved = decoded }
        return saved.advanced(to: date)
    }

    static func perform(_ action: CatAction) {
        let now = Date()
        var s = load(at: now)
        s.apply(action, at: now)
        if let data = try? JSONEncoder().encode(s) { UserDefaults.standard.set(data, forKey: key) }
    }
}
