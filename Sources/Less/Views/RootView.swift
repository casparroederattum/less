import SwiftUI

/// The frame around everything: two pages switched at the top, and the small privacy link.
struct RootView: View {
    @EnvironmentObject var model: AppModel
    @State private var showKnows = false

    var body: some View {
        VStack(spacing: 0) {
            topBar
            ZStack {
                switch model.page {
                case .scan: ScanFlowView().transition(.opacity)
                case .why: WhyLessView().transition(.opacity)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
        }
        .background(Theme.paper)
        .sheet(isPresented: $showKnows) {
            KnowsView().environmentObject(model)
        }
    }

    private var topBar: some View {
        ZStack {
            Picker("", selection: Binding(
                get: { model.page },
                set: { page in withAnimation(.easeInOut(duration: 0.25)) { model.page = page } }
            )) {
                Text("Scan").tag(Page.scan)
                Text("Why less").tag(Page.why)
            }
            .pickerStyle(.segmented)
            .labelsHidden()
            .frame(width: 220)

            HStack {
                Spacer()
                Button("What Less knows") { showKnows = true }
                    .buttonStyle(.plain)
                    .font(.system(size: 13))
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 8)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 14)
        .padding(.bottom, 6)
    }
}

/// The Scan page moves through its stages here: welcome, permissions, scanning, results.
struct ScanFlowView: View {
    @EnvironmentObject var model: AppModel

    var body: some View {
        Group {
            switch model.stage {
            case .welcome: WelcomeView()
            case .permission(let index): PermissionView(source: DataSource.allCases[index])
                .id(index)   // a fresh view per card, so each one fades in rather than morphing
            case .scanning: ScanningView()
            case .results: ResultsView()
            }
        }
        .transition(.opacity)
    }
}
