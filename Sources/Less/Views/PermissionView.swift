import SwiftUI

/// One permission at a time: what Less reads, why, what it never does. Allow or Skip.
struct PermissionView: View {
    @EnvironmentObject var model: AppModel
    let source: DataSource
    @State private var hasAccess = Permissions.hasFullDiskAccess()

    private var number: Int { (DataSource.allCases.firstIndex(of: source) ?? 0) + 1 }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                VStack(alignment: .leading, spacing: 10) {
                    Eyebrow(text: "\(number) of \(DataSource.allCases.count)")
                    Text(source.title)
                        .font(.system(size: 36, weight: .bold))
                }

                VStack(alignment: .leading, spacing: 22) {
                    row("What Less reads", source.reads)
                    row("Why", source.why)
                    row("What Less never does", source.never)
                    if let note = source.systemNote {
                        Text(note)
                            .font(.system(size: 13))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .card()

                if source.needsFullDiskAccess && !model.demo {
                    fullDiskAccess.card()
                }

                HStack(spacing: 12) {
                    Button("Allow") { model.choose(source, allowed: true) }
                        .buttonStyle(PrimaryButton())
                        .keyboardShortcut(.defaultAction)
                    Button("Skip") { model.choose(source, allowed: false) }
                        .buttonStyle(QuietButton())
                }

                Text("You can change your mind later from the results page. Anything macOS granted can be switched off in System Settings, under Privacy & Security.")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
                    .lineSpacing(2)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .frame(maxWidth: Theme.column, alignment: .leading)
            .padding(.horizontal, 40)
            .padding(.vertical, 40)
            .frame(maxWidth: .infinity)
        }
    }

    private func row(_ title: String, _ text: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title).font(.system(size: 13, weight: .semibold)).foregroundStyle(.secondary)
            Text(text)
                .font(.system(size: 17))
                .lineSpacing(4)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    /// macOS has no prompt for this one. The person switches it on, and we explain how.
    private var fullDiskAccess: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(spacing: 8) {
                Circle()
                    .fill(hasAccess ? Theme.accent : Color.secondary.opacity(0.4))
                    .frame(width: 8, height: 8)
                Text(hasAccess ? "Less can read this now." : "This needs one step in System Settings.")
                    .font(.system(size: 15, weight: .semibold))
            }

            if !hasAccess {
                VStack(alignment: .leading, spacing: 8) {
                    step(1, "Click Open System Settings below.")
                    step(2, "Find Less under Full Disk Access and switch it on. If it isn't listed, click the + button and choose Less.")
                    step(3, "macOS may ask Less to quit and reopen. That's fine; your choices are saved.")
                    step(4, "Come back here and click Check again.")
                }
                HStack(spacing: 10) {
                    Button("Open System Settings") { Permissions.openFullDiskAccessSettings() }
                        .buttonStyle(QuietButton())
                    Button("Show Less in Finder") { Permissions.revealAppInFinder() }
                        .buttonStyle(QuietButton())
                    Button("Check again") { hasAccess = Permissions.hasFullDiskAccess() }
                        .buttonStyle(QuietButton())
                }
                Text("You can also skip this. The scan works without it, just with less to go on.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            } else {
                Text("To take it back later, switch Less off in the same place.")
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func step(_ n: Int, _ text: String) -> some View {
        HStack(alignment: .firstTextBaseline, spacing: 10) {
            Text("\(n)")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(Theme.accent)
                .frame(width: 14, alignment: .trailing)
            Text(text)
                .font(.system(size: 15))
                .lineSpacing(3)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
