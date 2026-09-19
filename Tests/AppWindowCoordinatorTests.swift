import Cocoa

@MainActor
final class WindowTestDelegate: NSObject, NSApplicationDelegate {
    private let coordinator = AppWindowCoordinator()
    private let detector = MouseDetector()
    private var statusItem: NSStatusItem?

    func applicationDidFinishLaunching(_ notification: Notification) {
        DispatchQueue.main.async { self.runChecks() }
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool { false }

    private func runChecks() {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem?.button?.title = "NSS window test"
        var reports = 0
        detector.start { _ in reports += 1 }
        let snapshot = detector.connectedDevices
        precondition(reports == 1)
        var devices: NSWindow?
        var about: NSWindow?
        var deviceCreations = 0
        var aboutCreations = 0
        func create(_ title: String) -> NSWindow {
            let window = NSWindow(contentRect: NSRect(x: 100, y: 100, width: 320, height: 180),
                                  styleMask: [.titled, .closable, .miniaturizable], backing: .buffered, defer: false)
            window.title = title
            return window
        }
        func showDevices() {
            coordinator.show(.devices) {
                deviceCreations += 1
                let window = create("Devices — lifecycle test")
                devices = window
                return window
            }
        }
        func showAbout() {
            coordinator.show(.about) {
                aboutCreations += 1
                let window = create("About — lifecycle test")
                about = window
                return window
            }
        }
        coordinator.updateActivationPolicy()
        precondition(NSApp.activationPolicy() == .accessory)
        showDevices()
        precondition(NSApp.activationPolicy() == .regular && devices!.isVisible)
        devices!.performClose(nil) // User close-button path.
        precondition(NSApp.activationPolicy() == .accessory)
        showAbout()
        precondition(NSApp.activationPolicy() == .regular && about!.isVisible)
        about!.performClose(nil)
        precondition(NSApp.activationPolicy() == .accessory)
        showDevices()
        showAbout()
        coordinator.close(.devices) // Same path as disabling global control.
        precondition(NSApp.activationPolicy() == .regular && about!.isVisible)
        coordinator.close(.about)
        precondition(NSApp.activationPolicy() == .accessory)
        showDevices()
        showAbout()
        about!.performClose(nil) // Reverse close order.
        precondition(NSApp.activationPolicy() == .regular)
        devices!.miniaturize(nil)
        coordinator.updateActivationPolicy()
        precondition(NSApp.activationPolicy() == .regular)
        showDevices() // Reopening a minimized window must not create a duplicate.
        precondition(!devices!.isMiniaturized)
        coordinator.close(.devices)
        for _ in 0..<3 {
            showDevices()
            showDevices()
            showAbout()
            showAbout()
            coordinator.close(.about)
            precondition(NSApp.activationPolicy() == .regular)
            coordinator.close(.devices)
            precondition(NSApp.activationPolicy() == .accessory)
        }
        precondition(deviceCreations == 1 && aboutCreations == 1)
        precondition(devices!.delegate === coordinator && about!.delegate === coordinator)
        precondition(NSApp.isRunning && statusItem?.isVisible == true)
        precondition(detector.connectedDevices == snapshot)
        // Finish on a later main-loop turn to verify the app stays alive after closing.
        DispatchQueue.main.async {
            precondition(NSApp.isRunning && NSApp.activationPolicy() == .accessory)
            precondition(self.statusItem?.isVisible == true)
            self.detector.stop()
            if let statusItem = self.statusItem { NSStatusBar.system.removeStatusItem(statusItem) }
            print("PASS: startup accessory; each window regular; both close orders; last close accessory; minimized/repeated opens; window/delegate reuse; menu bar and HID detector retained")
            NSApp.terminate(nil)
        }
    }
}

@main struct WindowTests {
    @MainActor static func main() {
        let app = NSApplication.shared
        let delegate = WindowTestDelegate()
        app.delegate = delegate
        app.run()
        withExtendedLifetime(delegate) {}
    }
}
