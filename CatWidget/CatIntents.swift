import AppIntents
import WidgetKit

// Each tap on the widget runs one of these; iOS then redraws the widget.

struct PetCatIntent: AppIntent {
    static var title: LocalizedStringResource = "Pet Taro"
    func perform() async throws -> some IntentResult { CatStore.perform(.pet); return .result() }
}
struct FeedCatIntent: AppIntent {
    static var title: LocalizedStringResource = "Feed Taro"
    func perform() async throws -> some IntentResult { CatStore.perform(.feed); return .result() }
}
struct DrinkIntent: AppIntent {
    static var title: LocalizedStringResource = "Fresh water"
    func perform() async throws -> some IntentResult { CatStore.perform(.drink); return .result() }
}
struct PlayWithCatIntent: AppIntent {
    static var title: LocalizedStringResource = "Play with yarn"
    func perform() async throws -> some IntentResult { CatStore.perform(.yarn); return .result() }
}
struct PomPomIntent: AppIntent {
    static var title: LocalizedStringResource = "Swing the pom-pom"
    func perform() async throws -> some IntentResult { CatStore.perform(.pompom); return .result() }
}
struct WindowIntent: AppIntent {
    static var title: LocalizedStringResource = "Bird watching"
    func perform() async throws -> some IntentResult { CatStore.perform(.window); return .result() }
}
struct ToggleSleepIntent: AppIntent {
    static var title: LocalizedStringResource = "Nap time"
    func perform() async throws -> some IntentResult { CatStore.perform(.toggleSleep); return .result() }
}
