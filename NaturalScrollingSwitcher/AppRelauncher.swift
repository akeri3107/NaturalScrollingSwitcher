import Foundation
import Darwin

/// A separate instance of this executable waits for process exit without creating
/// NSApplication, windows, a HID manager, or a scroll monitor.
enum AppRelauncher {
    private static let helperArgument = "--nss-relaunch-helper"

    static func prepare() throws {
        guard let executable = Bundle.main.executableURL else {
            throw CocoaError(.executableNotLoadable)
        }
        let helper = Process()
        helper.executableURL = executable
        helper.arguments = [helperArgument, String(ProcessInfo.processInfo.processIdentifier)]
        helper.standardInput = FileHandle.nullDevice
        helper.standardOutput = FileHandle.nullDevice
        helper.standardError = FileHandle.nullDevice
        // Spawn before terminating. Process.run reports executable/launch errors
        // to the existing app, which rolls back the preference and stays open.
        try helper.run()
    }

    static func runHelperIfRequested() -> Bool {
        let arguments = CommandLine.arguments
        guard arguments.count == 3, arguments[1] == helperArgument else { return false }
        guard let parentPID = Int32(arguments[2]), parentPID > 1,
              parentPID != ProcessInfo.processInfo.processIdentifier else { return true }
        guard waitForExit(of: parentPID) else { return true }
        let open = Process()
        open.executableURL = URL(fileURLWithPath: "/usr/bin/open")
        // LaunchServices opens the bundle as a new normal launch after the old
        // process has exited; helper arguments are never forwarded to the app.
        open.arguments = ["-n", Bundle.main.bundleURL.path]
        do {
            try open.run()
            open.waitUntilExit()
        } catch {
            NSLog("NSS relaunch failed: %@", String(describing: error))
        }
        return true
    }

    static func waitForExit(of pid: Int32, timeout: DispatchTime = .now() + 30) -> Bool {
        let exited = DispatchSemaphore(value: 0)
        let source = DispatchSource.makeProcessSource(identifier: pid, eventMask: .exit,
                                                       queue: .global(qos: .utility))
        source.setEventHandler { exited.signal() }
        source.resume()
        defer { source.cancel() }
        // Covers termination before the helper registered its event source.
        if kill(pid, 0) == -1 && errno == ESRCH { return true }
        // If termination is ever cancelled, do not keep a helper alive forever.
        return exited.wait(timeout: timeout) == .success
    }
}
