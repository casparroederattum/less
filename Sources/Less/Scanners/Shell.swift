import Foundation

/// Runs one of macOS's own command-line tools (system_profiler, osascript) and returns what it printed.
enum Shell {
    /// Returns nil if the tool fails or takes too long. A stuck tool must never freeze the scan,
    /// so after `timeout` seconds it is stopped and we move on.
    static func run(_ path: String, _ arguments: [String], timeout: TimeInterval = 20) -> String? {
        let process = Process()
        process.executableURL = URL(fileURLWithPath: path)
        process.arguments = arguments
        let output = Pipe()
        process.standardOutput = output
        process.standardError = FileHandle.nullDevice   // unread error output could fill up and block the tool

        do { try process.run() } catch { return nil }

        let stopper = DispatchWorkItem { if process.isRunning { process.terminate() } }
        DispatchQueue.global().asyncAfter(deadline: .now() + timeout, execute: stopper)

        // Read before waiting: a tool with a lot to say would otherwise wait for us forever.
        let data = output.fileHandleForReading.readDataToEndOfFile()
        process.waitUntilExit()
        stopper.cancel()

        guard process.terminationStatus == 0 else { return nil }
        return String(data: data, encoding: .utf8)
    }
}
