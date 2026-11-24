import SwiftUI

/// A short essay, set like a page in a book. Text only, one column, nothing to click but the last line.
struct WhyLessView: View {
    @EnvironmentObject var model: AppModel

    /// Each section: an optional heading and its paragraphs.
    private let sections: [(heading: String?, paragraphs: [String])] = [
        (nil, [
            "Almost every piece of technology makes the same promise. It will take the friction out of something. Fewer steps, less waiting, less effort. And often it keeps that promise.",
            "But friction was rarely the only thing there. When the effort goes, the parts that came with it tend to go too. Some of them were the point.",
        ]),
        ("The useful inefficiency", [
            "Walking to the shop takes twenty minutes. On the way you see the street change with the season, you nod at a neighbour, you have a short, slightly awkward conversation with the person at the till. None of it is efficient. A lot of it is what a day is made of.",
            "Asking someone for directions is slower than a map. Writing a letter by hand is slower than typing. Cooking is slower than ordering. Each time, the slower way leaves something behind: a small encounter, a memory, a skill you didn't know you were building.",
            "Friction isn't always the enemy. Sometimes it is just life, happening at the speed of a person.",
        ]),
        ("Social, and being social", [
            "Social media is called social, and in a narrow sense it is. There are people in it. But being social mostly happens somewhere else: across a table, on a walk, in a room where someone can see your face when you laugh.",
            "An hour of scrolling can feel like being with people while leaving you more alone than before. It isn't that the apps are evil. It's that they are a thin version of something that is better thick.",
        ]),
        ("The number that runs your day", [
            "A band on your wrist can tell you how well you slept and how ready you are for the day. It is clever, and the numbers are often roughly right. The trouble starts when the number arrives before the feeling.",
            "You wake up, check the score, and the score tells you how you feel. A low number makes a good morning worse. A high one makes you ignore the tiredness in your legs. Slowly, measuring your body replaces listening to it. Your body was always the more honest instrument. It just doesn't come with a chart.",
        ]),
        ("Thinking you hand away", [
            "It has never been easier to get an answer. For a homework problem, an essay, a proof, there is always something that will do it for you, faster and neater.",
            "But the struggle was the learning. There is research suggesting that writing things down by hand, and the effort of pulling something back out of your own memory, help people understand and remember. The details are still being studied. The direction is not surprising. What you work out yourself, on paper, slowly, stays with you in a way that a borrowed answer does not.",
            "Using a tool to check your work is one thing. Using it so that you never do the work is another.",
        ]),
        ("Convenience that keeps you still", [
            "A trainer in the living room means you never have to ride in the rain. Delivery means you never have to carry anything home. Streaming means you never have to leave the sofa. Each one is reasonable on its own.",
            "Added up, they make a life that happens almost entirely indoors, mostly sitting, mostly alone. Nobody chose that. It arrived one convenience at a time.",
        ]),
        ("Chosen, not zero", [
            "None of this means technology is bad, or that the goal is to have none of it. A map in a strange city is a gift. A video call with family far away is a gift. Music on a long train ride is a gift.",
            "The point is that technology should serve a human life, not define it. It should be something you picked up on purpose, and could put down again.",
            "The goal isn't zero. It is chosen. Fewer things, each one earning its place.",
        ]),
    ]

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {
                Text("Why less")
                    .font(.system(size: 44, weight: .bold))
                    .padding(.bottom, 32)

                ForEach(sections.indices, id: \.self) { i in
                    let section = sections[i]
                    VStack(alignment: .leading, spacing: 16) {
                        if let heading = section.heading {
                            Text(heading)
                                .font(.system(size: 22, weight: .semibold))
                                .padding(.top, 20)
                        }
                        ForEach(section.paragraphs, id: \.self) { paragraph in
                            Text(paragraph)
                                .font(.system(size: 18))
                                .lineSpacing(8)
                                .fixedSize(horizontal: false, vertical: true)
                        }
                    }
                    .padding(.bottom, 20)
                }

                Button {
                    withAnimation(.easeInOut(duration: 0.25)) { model.page = .scan }
                } label: {
                    Text("When you're ready, see what you could live without.")
                        .font(.system(size: 18, weight: .medium))
                        .foregroundStyle(Theme.accent)
                        .underline(true, color: Theme.accent.opacity(0.4))
                }
                .buttonStyle(.plain)
                .padding(.top, 16)
            }
            .textSelection(.enabled)
            .frame(maxWidth: 600, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.vertical, 56)
            .frame(maxWidth: .infinity)
        }
    }
}
