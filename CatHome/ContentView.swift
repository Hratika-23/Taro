import SwiftUI

struct ContentView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                Text("🐱")
                    .font(.system(size: 80))
                    .frame(maxWidth: .infinity)
                Text("Taro lives on your Home Screen")
                    .font(.system(.title2, design: .rounded).weight(.bold))
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    step("1", "Go to your Home Screen and press and hold on an empty spot.")
                    step("2", "Tap Edit in the top-left corner, then Add Widget.")
                    step("3", "Search for “Taro”, pick the big size, and tap Add Widget.")
                }

                Text("How to play")
                    .font(.system(.headline, design: .rounded))
                VStack(alignment: .leading, spacing: 8) {
                    Text("✋  Tap Taro to pet him")
                    Text("🍗  Tap the bowl to feed him")
                    Text("🧶  Tap the yarn to play")
                    Text("💡  Tap the lamp or bed for bedtime / wake up")
                }
                .font(.system(.body, design: .rounded))

                Text("He gets hungry, bored and sleepy over time, and naps on his own at night.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
            .padding(24)
        }
    }

    private func step(_ n: String, _ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Text(n)
                .font(.system(.subheadline, design: .rounded).weight(.bold))
                .frame(width: 26, height: 26)
                .background(Circle().fill(Color.orange.opacity(0.25)))
            Text(text)
        }
    }
}
