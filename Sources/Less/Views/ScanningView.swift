import SwiftUI

/// Shows, in plain words, what is being looked at right now, and what is already done.
/// No percentages and no spinning wheel: the list itself is the progress.
struct ScanningView: View {
    @EnvironmentObject var model: AppModel

    private var sources: [DataSource] {
        DataSource.allCases.filter { model.demo || model.isAllowed($0) }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 32) {
            Text(model.current.isEmpty ? "Getting ready" : model.current + "…")
                .font(.system(size: 30, weight: .semibold))
                .animation(.easeInOut(duration: 0.25), value: model.current)
                .id(model.current)
                .transition(.opacity)

            if sources.isEmpty {
                Text("Nothing was allowed, so there is nothing to look at. You can still add things by hand on the next page.")
                    .font(.system(size: 16))
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 14) {
                    ForEach(sources) { source in
                        let done = model.progress.contains(source)
                        HStack(spacing: 12) {
                            Image(systemName: done ? "checkmark.circle.fill" : "circle")
                                .foregroundStyle(done ? Theme.accent : Color.secondary.opacity(0.5))
                                .font(.system(size: 15))
                            Text(source.title)
                                .font(.system(size: 16))
                                .foregroundStyle(done ? .primary : .secondary)
                        }
                    }
                }
                .card()
            }
        }
        .frame(maxWidth: Theme.column, alignment: .leading)
        .padding(40)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
