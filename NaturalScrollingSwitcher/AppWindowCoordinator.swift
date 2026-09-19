import Cocoa

/// Owns the app's ordinary windows; menu bar/popup windows never affect Dock state.
@MainActor
final class AppWindowCoordinator: NSObject, NSWindowDelegate {
    enum Kind: Hashable { case devices, about }

    private var windows: [Kind: NSWindow] = [:]
    private var openWindows = Set<Kind>()

    func show(_ kind: Kind, create: () -> NSWindow) {
        let window: NSWindow
        if let existing = windows[kind] {
            window = existing
        } else {
            window = create()
            window.isReleasedWhenClosed = false
            window.delegate = self
            windows[kind] = window
        }
        openWindows.insert(kind)
        updateActivationPolicy()
        if window.isMiniaturized { window.deminiaturize(nil) }
        window.makeKeyAndOrderFront(nil)
        NSApp.activate(ignoringOtherApps: true)
    }

    func close(_ kind: Kind) {
        windows[kind]?.close()
    }

    func windowWillClose(_ notification: Notification) {
        guard let window = notification.object as? NSWindow,
              let kind = windows.first(where: { $0.value === window })?.key else { return }
        // isVisible can still be true in this callback. Track explicit opens and
        // closes instead, keeping minimized windows in the open set as well.
        openWindows.remove(kind)
        updateActivationPolicy()
    }

    func updateActivationPolicy() {
        let policy: NSApplication.ActivationPolicy = openWindows.isEmpty ? .accessory : .regular
        if NSApp.activationPolicy() != policy {
            NSApp.setActivationPolicy(policy)
        }
    }
}
