import SwiftUI

/// Where the app starts. One window, nothing else: no menu bar icon, no background helper.
/// Less shouldn't do the thing it asks other apps not to do.
@main
struct LessApp: App {
    @StateObject private var model = AppModel()
    @NSApplicationDelegateAdaptor(QuitWhenClosed.self) private var delegate

    var body: some Scene {
        WindowGroup("Less") {
            RootView()
                .environmentObject(model)
                .frame(minWidth: 760, minHeight: 640)
                .tint(Theme.accent)
                .preferredColorScheme(.light)   // white and black, never dark
        }
        .defaultSize(width: 900, height: 780)
        .windowResizability(.contentMinSize)
        .commands {
            // Less has one window and no documents; "New Window" would only confuse.
            CommandGroup(replacing: .newItem) {}
        }
    }
}

/// Quit when the window closes. A closed app that keeps running is exactly what Less questions.
final class QuitWhenClosed: NSObject, NSApplicationDelegate {
    // Also tells macOS itself (menus, sheets, dialogs) to stay light.
    func applicationWillFinishLaunching(_ notification: Notification) {
        NSApp.appearance = NSAppearance(named: .aqua)
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { true }
}
