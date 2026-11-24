import SwiftUI

/// The first screen. One question, a few promises in plain words, one button.
struct WelcomeView: View {
    @EnvironmentObject var model: AppModel

    private let promises: [(title: String, text: String)] = [
        ("Everything stays on this Mac.",
         "No account, no cloud, no tracking, no ads. Nothing is sent anywhere."),
        ("You choose what Less looks at.",
         "Each kind of information gets its own question. Skipping is always fine."),
        ("Only numbers are kept.",
         "Minutes, counts and site names. Never messages, pages or screenshots."),
        ("Less will never sell your data or show ads.",
         "If it ever costs money, it will be one simple price, or paid by employers who want healthier teams. Never by your attention."),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 36) {
                VStack(alignment: .leading, spacing: 14) {
                    Text("What could you live without?")
                        .font(.system(size: 44, weight: .bold))
                        .fixedSize(horizontal: false, vertical: true)
                    Text("Less looks at the technology on this Mac and tells you, kindly, what you might turn down or let go of. And what to do instead.")
                        .font(.system(size: 19))
                        .foregroundStyle(.secondary)
                        .lineSpacing(5)
                        .fixedSize(horizontal: false, vertical: true)
                }

                VStack(alignment: .leading, spacing: 20) {
                    ForEach(promises, id: \.title) { promise in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(promise.title).font(.system(size: 15, weight: .semibold))
                            Text(promise.text)
                                .font(.system(size: 15))
                                .foregroundStyle(.secondary)
                                .lineSpacing(3)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                }
                .card()

                VStack(alignment: .leading, spacing: 14) {
                    Button("Start scan") { model.start() }
                        .buttonStyle(PrimaryButton())
                        .keyboardShortcut(.defaultAction)
                    Text("The best outcome is that you need us less.")
                        .font(.system(size: 13))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: Theme.column, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.vertical, 48)
            .frame(maxWidth: .infinity)
        }
    }
}
