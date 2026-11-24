import Foundation

/// Paired Bluetooth devices, read from macOS's own System Information tool.
/// We only want names and whether they are connected; we never talk to the devices.
struct BluetoothScanner: SourceScanner {
    let source = DataSource.bluetooth

    func scan() async -> ScanResult {
        guard let json = Shell.run("/usr/sbin/system_profiler", ["SPBluetoothDataType", "-json"], timeout: 30),
              let data = json.data(using: .utf8),
              let devices = Self.parse(data) else {
            return ScanResult(items: [], report: SourceReport(
                source: source, readable: false, summary: "Bluetooth devices couldn't be read."))
        }

        var items: [Item] = []
        for device in devices {
            let category = Categories.forDevice(name: device.name + " " + device.type)
            // Keyboards and mice are part of using a computer. Unknown gadgets get a card;
            // they might be exactly the thing worth questioning.
            guard category != .tools else { continue }
            var item = Item(id: "device:\(device.name)", name: device.name, kind: .device, category: category)
            item.signals.connectedNow = device.connected
            items.append(item)
        }
        return ScanResult(items: items, report: SourceReport(
            source: source, readable: true,
            summary: "Names of \(devices.count) paired Bluetooth devices, and whether each was connected."))
    }

    struct Device { var name: String; var type: String; var connected: Bool }

    /// The JSON looks like:
    /// { "SPBluetoothDataType": [ { "device_connected": [ { "AirPods": { "device_minorType": "Headphones" } } ],
    ///                              "device_not_connected": [ ... ] } ] }
    /// Each device is a one-entry dictionary: its name maps to its details.
    static func parse(_ data: Data) -> [Device]? {
        guard let root = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let sections = root["SPBluetoothDataType"] as? [[String: Any]] else { return nil }
        var devices: [Device] = []
        for section in sections {
            for (key, connected) in [("device_connected", true), ("device_not_connected", false)] {
                for entry in section[key] as? [[String: Any]] ?? [] {
                    for (name, details) in entry {
                        let type = (details as? [String: Any])?["device_minorType"] as? String ?? ""
                        devices.append(Device(name: name, type: type, connected: connected))
                    }
                }
            }
        }
        return devices
    }
}
