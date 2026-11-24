import SwiftUI

/// The answer: one calm summary, then one card per thing, then the short "fill the gaps" list.
struct ResultsView: View {
    @EnvironmentObject var model: AppModel

    private var scan: ScanRecord? { model.saved.lastScan }
    private var items: [Item] { scan?.items ?? [] }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                SummaryCard(scan: scan, previous: model.saved.previousScan)

                ForEach(Verdict.allCases, id: \.self) { verdict in
                    let group = items.filter { $0.verdict == verdict }
                    if !group.isEmpty {
                        VStack(alignment: .leading, spacing: 14) {
                            Eyebrow(text: verdict.title)
                            ForEach(group) { item in
                                ItemCard(item: item, before: before(item))
                            }
                        }
                    }
                }

                if let quiet = scan?.quietCount, quiet > 0 {
                    Text("\(quiet) other apps looked fine, so they don't get a card.")
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                }

                FillTheGaps()

                HStack(spacing: 12) {
                    Button("Scan again") { model.rescan() }
                        .buttonStyle(PrimaryButton())
                    Button("Change what Less looks at") { model.reviewPermissions() }
                        .buttonStyle(QuietButton())
                }
                .padding(.top, 8)
            }
            .frame(maxWidth: Theme.column, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        }
    }

    /// The same thing in the previous scan, if there was one, to show what changed.
    private func before(_ item: Item) -> Item? {
        model.saved.previousScan?.items.first { $0.id == item.id }
    }
}

/// "You could let go of 4 things and reduce 3." Plus what changed since last time.
struct SummaryCard: View {
    let scan: ScanRecord?
    let previous: ScanRecord?

    private func count(_ v: Verdict, in record: ScanRecord?) -> Int {
        record?.items.filter { $0.verdict == v }.count ?? 0
    }

    var body: some View {
        let letGo = count(.letGo, in: scan)
        let reduce = count(.reduce, in: scan)
        let done = scan?.items.filter(\.done).count ?? 0

        VStack(alignment: .leading, spacing: 12) {
            Text(headline(letGo: letGo, reduce: reduce))
                .font(.system(size: 34, weight: .bold))
                .fixedSize(horizontal: false, vertical: true)

            if done > 0 {
                Text("You've already done \(done) of them.")
                    .font(.system(size: 17))
                    .foregroundStyle(Theme.accent)
            }
            if let previous {
                Text(since(previous, letGo: letGo, reduce: reduce))
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            } else if let scan {
                Text("Looked at on \(Format.day(scan.date)). Come back in a few weeks and scan again to see what changed.")
                    .font(.system(size: 15))
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(.bottom, 8)
    }

    private func headline(letGo: Int, reduce: Int) -> String {
        func things(_ n: Int) -> String { n == 1 ? "1 thing" : "\(n) things" }
        switch (letGo, reduce) {
        case (0, 0): return "Nothing here needs changing."
        case (_, 0): return "You could let go of \(things(letGo))."
        case (0, _): return "You could reduce \(things(reduce))."
        default: return "You could let go of \(things(letGo)) and reduce \(reduce)."
        }
    }

    private func since(_ previous: ScanRecord, letGo: Int, reduce: Int) -> String {
        let before = count(.letGo, in: previous) + count(.reduce, in: previous)
        let now = letGo + reduce
        let date = Format.day(previous.date)
        if now < before { return "On \(date) it was \(before). That's \(before - now) fewer." }
        if now > before { return "On \(date) it was \(before)." }
        return "The same number as on \(date)."
    }
}

/// One thing: the verdict, why, what to do instead, and what it's based on.
struct ItemCard: View {
    @EnvironmentObject var model: AppModel
    let item: Item
    let before: Item?

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(item.name)
                    .font(.system(size: 21, weight: .semibold))
                    .lineLimit(2)
                Spacer(minLength: 12)
                Text(item.verdict.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(item.verdict == .keep ? Color.secondary : Theme.accent)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 4)
                    .background(Capsule().fill(item.verdict == .keep ? Color.secondary.opacity(0.1) : Theme.soft))
            }

            Text(item.why)
                .font(.system(size: 16))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)

            if item.verdict != .keep {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("Instead")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundStyle(Theme.accent)
                    Text(item.instead)
                        .font(.system(size: 16))
                        .lineSpacing(3)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }

            Text(item.basedOn)
                .font(.system(size: 12))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            if let change = changeLine {
                Text(change)
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }

            if item.verdict != .keep {
                Button { model.toggleDone(item.id) } label: {
                    Label(item.done ? "Done" : "Mark as done",
                          systemImage: item.done ? "checkmark.circle.fill" : "circle")
                }
                .buttonStyle(QuietButton())
                .padding(.top, 2)
            }
        }
        .card()
        .opacity(item.done ? 0.6 : 1)
        .animation(.easeInOut(duration: 0.2), value: item.done)
    }

    /// "Last time: 2h 10m a day" when the time changed noticeably since the previous scan.
    private var changeLine: String? {
        guard let old = before?.signals.minutesPerDay, let now = item.signals.minutesPerDay,
              abs(old - now) >= 5 else { return nil }
        return "Last time: \(Format.duration(minutes: old)) a day."
    }
}

/// Things a Mac can't see. One tap adds them; a second tap takes them away again.
struct FillTheGaps: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Eyebrow(text: "What this Mac can't see")
            Text("Your phone, things you wear, and services you pay for don't show up here. Add any that are part of your life.")
                .font(.system(size: 15))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            LazyVGrid(columns: [GridItem(.adaptive(minimum: 190), spacing: 10)], alignment: .leading, spacing: 10) {
                ForEach(GapSuggestion.all) { suggestion in
                    let added = model.isAdded(suggestion)
                    Button { model.toggleAdded(suggestion) } label: {
                        HStack(spacing: 8) {
                            Image(systemName: added ? "checkmark" : "plus")
                                .font(.system(size: 12, weight: .semibold))
                            Text(suggestion.name)
                                .font(.system(size: 14))
                            Spacer(minLength: 0)
                        }
                        .foregroundStyle(added ? Theme.accent : Color.primary)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(
                            RoundedRectangle(cornerRadius: 12, style: .continuous)
                                .fill(added ? Theme.soft : Theme.card)
                        )
                        .contentShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
            }
        }
        .padding(.top, 12)
    }
}
