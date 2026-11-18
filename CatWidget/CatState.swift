import Foundation

// MARK: - The cat's life

enum CatReaction: String, Codable {
    case none, petted, purrInSleep, eating, playing, tooTired, full, wokeUp, fellAsleep, grumpy
}

enum CatMood { case happy, okay, hungry, bored, tired }

enum CatPose { case sitting, eating, playing, sleeping }

enum CatAction { case pet, feed, play, toggleSleep }

struct CatState: Codable, Equatable {
    var fullness: Double = 75      // 0 = starving, 100 = stuffed
    var fun: Double = 70           // 0 = bored, 100 = delighted
    var energy: Double = 85        // 0 = exhausted, 100 = full of beans
    var isSleeping: Bool = false
    var reaction: CatReaction = .none
    var reactionUntil: Date = .distantPast
    var lastInteraction: Date = .distantPast
    var sleptAt: Date = .distantPast
    var updatedAt: Date = Date()
    var hearts: Int = 0            // how many times you have petted him

    // How fast things change, per hour
    static let hungerRate = 6.0
    static let boredomRate = 7.0
    static let tireRate = 5.0
    static let restRate = 22.0

    /// Bedtime for the cat (he naps on his own at night unless you're playing).
    static func isNight(_ date: Date) -> Bool {
        let h = Calendar.current.component(.hour, from: date)
        return h >= 23 || h < 7
    }

    /// Lets time pass for the cat, from `updatedAt` up to `date`, in 10-minute steps.
    func advanced(to date: Date) -> CatState {
        var s = self
        let maxSpan: TimeInterval = 14 * 24 * 3600
        var t = max(s.updatedAt, date.addingTimeInterval(-maxSpan))
        while t < date {
            let next = min(date, t.addingTimeInterval(600))
            let h = next.timeIntervalSince(t) / 3600
            s.fullness = max(0, s.fullness - h * Self.hungerRate)
            if s.isSleeping {
                s.fun = max(0, s.fun - h * Self.boredomRate * 0.2)
                s.energy = min(100, s.energy + h * Self.restRate)
                let napLongEnough = next.timeIntervalSince(s.sleptAt) > 45 * 60
                if s.energy >= 95 && napLongEnough && !Self.isNight(next) {
                    s.isSleeping = false
                }
            } else {
                s.fun = max(0, s.fun - h * Self.boredomRate)
                s.energy = max(0, s.energy - h * Self.tireRate)
                let idle = next.timeIntervalSince(s.lastInteraction) > 20 * 60
                if s.energy <= 8 || (Self.isNight(next) && idle) {
                    s.isSleeping = true
                    s.sleptAt = next
                }
            }
            t = next
        }
        if date > s.updatedAt { s.updatedAt = date }
        if date >= s.reactionUntil { s.reaction = .none }
        return s
    }

    private mutating func react(_ r: CatReaction, _ now: Date, _ seconds: TimeInterval) {
        reaction = r
        reactionUntil = now.addingTimeInterval(seconds)
    }

    mutating func apply(_ action: CatAction, at now: Date) {
        self = advanced(to: now)
        lastInteraction = now
        switch action {
        case .pet:
            hearts += 1
            if isSleeping {
                fun = min(100, fun + 3)
                react(.purrInSleep, now, 6)
            } else {
                fun = min(100, fun + 8)
                react(.petted, now, 8)
            }
        case .feed:
            if fullness >= 92 {
                react(.full, now, 6)
            } else {
                isSleeping = false
                fullness = min(100, fullness + 35)
                react(.eating, now, 14)
            }
        case .play:
            if isSleeping {
                isSleeping = false
                react(.grumpy, now, 6)
            } else if energy < 15 {
                react(.tooTired, now, 6)
            } else {
                fun = min(100, fun + 25)
                energy = max(0, energy - 8)
                fullness = max(0, fullness - 3)
                react(.playing, now, 14)
            }
        case .toggleSleep:
            if isSleeping {
                isSleeping = false
                react(.wokeUp, now, 6)
            } else {
                isSleeping = true
                sleptAt = now
                react(.fellAsleep, now, 6)
            }
        }
    }

    // MARK: What the widget shows

    var pose: CatPose {
        if isSleeping { return .sleeping }
        switch reaction {
        case .eating: return .eating
        case .playing: return .playing
        default: return .sitting
        }
    }

    var mood: CatMood {
        if fullness < 25 { return .hungry }
        if energy < 20 { return .tired }
        if fun < 25 { return .bored }
        if fullness > 55 && fun > 55 && energy > 40 { return .happy }
        return .okay
    }

    var message: String? {
        switch reaction {
        case .petted: return "Purrrr… ♥"
        case .purrInSleep: return "mrrp… zzz"
        case .eating: return "Nom nom nom!"
        case .playing: return "Gotcha, yarn!"
        case .tooTired: return "Too sleepy to play…"
        case .full: return "I'm full, thanks!"
        case .wokeUp: return "Mrrow? I'm up!"
        case .fellAsleep: return "Goodnight…"
        case .grumpy: return "Hey! I was napping 😾"
        case .none: break
        }
        if isSleeping { return nil }
        switch mood {
        case .hungry: return "I'm hungry… 🍗"
        case .bored: return "Play with me!"
        case .tired: return "So sleepy…"
        default: return nil
        }
    }
}

// MARK: - Saving

enum CatStore {
    private static let key = "mochi.state.v1"

    static func load(at date: Date = Date()) -> CatState {
        var saved = CatState()
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode(CatState.self, from: data) {
            saved = decoded
        }
        return saved.advanced(to: date)
    }

    static func perform(_ action: CatAction) {
        let now = Date()
        var s = load(at: now)
        s.apply(action, at: now)
        if let data = try? JSONEncoder().encode(s) {
            UserDefaults.standard.set(data, forKey: key)
        }
    }
}
