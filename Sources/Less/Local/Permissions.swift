import AppKit
import CoreBluetooth

/// The few places where Less has to ask macOS for something.
enum Permissions {

    /// Full Disk Access can't be asked for with a prompt; the person has to switch it on.
    /// The only honest test is to try reading a protected file.
    static func hasFullDiskAccess() -> Bool {
        let home = FileManager.default.homeDirectoryForCurrentUser
        let protected = ["Library/Safari/History.db",
                         "Library/Application Support/Knowledge/knowledgeC.db",
                         "Library/Safari/Bookmarks.plist"]
        for path in protected {
            let url = home.appendingPathComponent(path)
            guard FileManager.default.fileExists(atPath: url.path) else { continue }
            if let handle = try? FileHandle(forReadingFrom: url) {
                try? handle.close()
                return true
            }
        }
        return false
    }

    static func openFullDiskAccessSettings() {
        open("x-apple.systempreferences:com.apple.preference.security?Privacy_AllFiles")
    }

    static func openNotificationSettings() {
        open("x-apple.systempreferences:com.apple.Notifications-Settings.extension")
    }

    static func openPrivacySettings() {
        open("x-apple.systempreferences:com.apple.preference.security")
    }

    static func revealAppInFinder() {
        NSWorkspace.shared.activateFileViewerSelecting([Bundle.main.bundleURL])
    }

    private static func open(_ link: String) {
        if let url = URL(string: link) { NSWorkspace.shared.open(url) }
    }

    // MARK: Bluetooth

    /// Creating a Bluetooth manager is what makes macOS show its question. We keep it alive
    /// until the person has answered, then let it go: Less never uses Bluetooth itself.
    @MainActor static var bluetoothAsker: BluetoothAsker?

    @MainActor
    static func askForBluetooth() {
        bluetoothAsker = BluetoothAsker()
    }
}

final class BluetoothAsker: NSObject, CBCentralManagerDelegate {
    private var manager: CBCentralManager?

    override init() {
        super.init()
        manager = CBCentralManager(delegate: self, queue: nil)
    }

    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        // Any real answer, yes or no, means the question has been asked. Nothing more to do.
        if central.state != .unknown && central.state != .resetting { manager = nil }
    }
}
