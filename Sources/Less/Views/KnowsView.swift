import SwiftUI

/// "What Less knows": exactly what was read, in plain words, and a button that really deletes it.
struct KnowsView: View {
    @EnvironmentObject var model: AppModel
    @Environment(\.dismiss) private var dismiss
    @State private var confirming = false

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("What Less knows")
                            .font(.system(size: 30, weight: .bold))
                        Text(model.saved.lastScan == nil
                             ? "Nothing yet. Less hasn't looked at anything."
                             : "Everything below lives in one small file on this Mac. None of it has left it.")
                            .font(.system(size: 15))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    if model.saved.lastScan != nil {
                        sourcesList.card()
                        kept.card()
                    }
                    howToTakeBack.card()
                }
                .padding(32)
            }

            Divider()
            HStack {
                Button("Delete everything", role: .destructive) { confirming = true }
                    .disabled(model.saved.lastScan == nil && model.saved.choices.isEmpty)
                Spacer()
                Button("Close") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
            .padding(20)
        }
        .frame(width: 560, height: 640)
        .background(Theme.paper)
        .confirmationDialog("Delete everything Less knows?", isPresented: $confirming) {
            Button("Delete everything", role: .destructive) {
                model.deleteEverything()
                dismiss()
            }
        } message: {
            Text("The file is removed from this Mac. Less starts again as if it was just installed.")
        }
    }

    private var sourcesList: some View {
        VStack(alignment: .leading, spacing: 16) {
            Eyebrow(text: "What was read in the last scan")
            ForEach(DataSource.allCases) { source in
                VStack(alignment: .leading, spacing: 3) {
                    Text(source.title).font(.system(size: 15, weight: .semibold))
                    Text(line(for: source))
                        .font(.system(size: 14))
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
    }

    private func line(for source: DataSource) -> String {
        if let report = model.saved.reports.first(where: { $0.source == source }) { return report.summary }
        return model.isAllowed(source) ? "Allowed, but nothing was read yet." : "Skipped. Nothing was read."
    }

    private var kept: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "What is kept")
            Text("For each card: a name, a few numbers like minutes and counts, the verdict, and whether you marked it done. The results of the scan before, to show what changed. Nothing else.")
                .font(.system(size: 14))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Text(Store.file.path)
                .font(.system(size: 12, design: .monospaced))
                .foregroundStyle(.secondary)
                .textSelection(.enabled)
        }
    }

    private var howToTakeBack: some View {
        VStack(alignment: .leading, spacing: 10) {
            Eyebrow(text: "Taking permissions back")
            Text("Open System Settings, then Privacy & Security. Full Disk Access, Bluetooth, Local Network and Automation each have a list; switch Less off in any of them. Less keeps working with whatever is left.")
                .font(.system(size: 14))
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
            Button("Open Privacy & Security") { Permissions.openPrivacySettings() }
                .buttonStyle(QuietButton())
        }
    }
}
