//
//  NaturalScrollingSwitcherApp.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import SwiftUI
import AppKit

@main
struct NaturalScrollingSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                monitor: appDelegate.monitor,
                loginItemManager: appDelegate.loginItemManager
            )
        }
        label: {
            Image(nsImage: menuBarIcon)
        }
        .menuBarExtraStyle(.menu)
    }
}

struct MenuBarView: View {

    @ObservedObject var monitor: ScrollMonitor
    @ObservedObject var loginItemManager: LoginItemManager

    @State private var creditsWindow: NSWindow?

    var body: some View {

        VStack {

            Button {
                showCredits()
            } label: {
                Text("Natural Scrolling Switcher")
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Divider()

            if monitor.mouseConnected {
                Label(
                    "Mouse connected",
                    systemImage: "computermouse"
                )
            } else {
                Label(
                    "Trackpad only",
                    systemImage: "hand.point.up.left"
                )
            }

            Text(
                monitor.naturalScrollingEnabled
                    ? "Natural Scrolling: ON"
                    : "Natural Scrolling: OFF"
            )
            .foregroundStyle(.secondary)

            Divider()

            Toggle(
                "Launch at login",
                isOn: Binding(
                    get: {
                        loginItemManager.isEnabled
                    },
                    set: { newValue in
                        loginItemManager.setEnabled(newValue)
                    }
                )
            )

            Menu("Natural Scrolling") {

                Button {
                    monitor.setMode(.on)
                } label: {
                    HStack {
                        Text("ON")

                        if monitor.naturalScrollingMode == .on {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    monitor.setMode(.off)
                } label: {
                    HStack {
                        Text("OFF")

                        if monitor.naturalScrollingMode == .off {
                            Image(systemName: "checkmark")
                        }
                    }
                }

                Button {
                    monitor.setMode(.automatic)
                } label: {
                    HStack {
                        Text("Auto")

                        if monitor.naturalScrollingMode == .automatic {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }

            Divider()

            Button("Quit Natural Scrolling Switcher") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }

    private func showCredits() {

        if let existingWindow = creditsWindow {
            existingWindow.makeKeyAndOrderFront(nil)
            NSApp.activate(ignoringOtherApps: true)
            return
        }

        let hostingController = NSHostingController(
            rootView: CreditsView()
        )

        let window = NSWindow(
            contentViewController: hostingController
        )

        window.title = "About Natural Scrolling Switcher"

        window.styleMask = [
            .titled,
            .closable
        ]

        window.isReleasedWhenClosed = false
        window.center()
        window.makeKeyAndOrderFront(nil)

        NSApp.activate(ignoringOtherApps: true)

        creditsWindow = window
    }
}
