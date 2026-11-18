import AppIntents
import WidgetKit

// Each tap on the widget runs one of these. After it finishes,
// iOS redraws the widget automatically.

struct PetCatIntent: AppIntent {
    static var title: LocalizedStringResource = "Pet Taro"
    func perform() async throws -> some IntentResult {
        CatStore.perform(.pet)
        return .result()
    }
}

struct FeedCatIntent: AppIntent {
    static var title: LocalizedStringResource = "Feed Taro"
    func perform() async throws -> some IntentResult {
        CatStore.perform(.feed)
        return .result()
    }
}

struct PlayWithCatIntent: AppIntent {
    static var title: LocalizedStringResource = "Play with Taro"
    func perform() async throws -> some IntentResult {
        CatStore.perform(.play)
        return .result()
    }
}

struct ToggleSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Lights on / off"
    func perform() async throws -> some IntentResult {
        CatStore.perform(.toggleSleep)
        return .result()
    }
}
