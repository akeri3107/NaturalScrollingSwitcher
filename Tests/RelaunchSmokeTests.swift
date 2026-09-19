import Foundation
import Darwin

/// A headless test bundle: uses the production helper and LaunchServices without
/// starting NSS, requesting HID access, or touching application preferences.
@main
struct RelaunchSmokeTests {
    static func main() throws {
        if AppRelauncher.runHelperIfRequested() { return }
        let marker = Bundle.main.bundleURL.deletingPathExtension().appendingPathExtension("marker")
        if CommandLine.arguments.contains("--start") {
            try String(ProcessInfo.processInfo.processIdentifier).write(to: marker, atomically: true, encoding: .utf8)
            try AppRelauncher.prepare()
            return
        }
        let previousPID = Int32(try String(contentsOf: marker, encoding: .utf8))!
        precondition(kill(previousPID, 0) == -1 && errno == ESRCH)
        try "PASS: helper relaunched bundle after old process exit".write(to: marker, atomically: true, encoding: .utf8)
    }
}
