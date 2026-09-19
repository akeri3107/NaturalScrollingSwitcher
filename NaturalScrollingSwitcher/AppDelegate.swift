//
//  AppDelegate.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Cocoa
import Combine
import SwiftUI

final class AppDelegate: NSObject, NSApplicationDelegate {

    let languageSettings = LanguageSettings()
    let monitor: ScrollMonitor
    let loginItemManager = LoginItemManager()
    let devicePolicyStore = DevicePolicyStore()
    private let windows = AppWindowCoordinator()
    private var controlSubscription: AnyCancellable?

    override init() {
        let detector = MouseDetector()
        monitor = ScrollMonitor(mouseDetector: detector, policyStore: devicePolicyStore)
        super.init()
        controlSubscription = monitor.$isControlEnabled.sink { [weak self] enabled in
            if !enabled { self?.windows.close(.devices) }
        }
    }

    func showDevices() {
        guard monitor.isControlEnabled else { return }
        windows.show(.devices) {
            let window = NSWindow(contentViewController: NSHostingController(
                rootView: DevicesView(store: devicePolicyStore).environment(\.locale, L10n.locale)
            ))
            window.title = L10n.devicesTitle
            window.styleMask = [.titled, .closable, .miniaturizable, .resizable]
            window.setContentSize(NSSize(width: 680, height: 460))
            window.center()
            return window
        }
    }

    func showCredits() {
        windows.show(.about) {
            let window = NSWindow(contentViewController: NSHostingController(rootView: CreditsView().environment(\.locale, L10n.locale)))
            window.title = L10n.aboutTitle
            window.styleMask = [.titled, .closable]
            window.center()
            return window
        }
    }

    func selectLanguage(_ preference: LanguagePreference) {
        do {
            let result = try languageSettings.select(preference, confirm: {
                let alert = NSAlert()
                alert.messageText = L10n.languageChangeTitle
                alert.informativeText = L10n.languageChangeMessage
                alert.addButton(withTitle: L10n.buttonRestart)
                alert.addButton(withTitle: L10n.buttonCancel).keyEquivalent = "\u{1b}"
                NSApp.activate(ignoringOtherApps: true)
                return alert.runModal() == .alertFirstButtonReturn
            }, prepareRelaunch: { try AppRelauncher.prepare() })
            if result == .restart { NSApp.terminate(nil) }
        } catch {
            NSLog("NSS could not prepare relaunch: %@", String(describing: error))
            let alert = NSAlert()
            alert.messageText = L10n.languageChangeTitle
            alert.informativeText = L10n.languageRestartFailed
            alert.addButton(withTitle: L10n.buttonClose)
            alert.runModal()
        }
    }

    func applicationDidFinishLaunching(_ notification: Notification) {
        windows.updateActivationPolicy()

        monitor.start()
    }

    func applicationWillTerminate(_ notification: Notification) {
        monitor.stop()
    }

    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        false
    }
}
