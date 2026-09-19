//
//  NaturalScrollingSwitcherApp.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import SwiftUI
import AppKit

struct NaturalScrollingSwitcherApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self)
    private var appDelegate

    var body: some Scene {
        MenuBarExtra {
            MenuBarView(
                monitor: appDelegate.monitor,
                loginItemManager: appDelegate.loginItemManager,
                languageSettings: appDelegate.languageSettings,
                selectLanguage: appDelegate.selectLanguage,
                showDevices: { appDelegate.showDevices() },
                showCredits: { appDelegate.showCredits() }
            )
            .environment(\.locale, L10n.locale)
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
    @ObservedObject var languageSettings: LanguageSettings
    let selectLanguage: (LanguagePreference) -> Void
    let showDevices: () -> Void

    let showCredits: () -> Void

    var body: some View {

        VStack {

            Button {
                showCredits()
            } label: {
                Text(L10n.menuAbout)
                    .font(.headline)
                    .foregroundStyle(.primary)
            }
            .buttonStyle(.plain)

            Divider()

            if monitor.mouseConnected {
                Label(
                    L10n.menuMouseConnected,
                    systemImage: "computermouse"
                )
            } else {
                Label(
                    L10n.menuTrackpadOnly,
                    systemImage: "hand.point.up.left"
                )
            }

            Text(
                !monitor.isControlEnabled
                    ? L10n.menuControlDisabled
                    : (monitor.naturalScrollingEnabled ? L10n.menuScrollingOn : L10n.menuScrollingOff)
            )
            .foregroundStyle(.secondary)

            Divider()

            Toggle(
                L10n.menuLaunchAtLogin,
                isOn: Binding(
                    get: {
                        loginItemManager.isEnabled
                    },
                    set: { newValue in
                        loginItemManager.setEnabled(newValue)
                    }
                )
            )

            Menu(L10n.menuNaturalScrolling) {
                Button {
                    monitor.setControlEnabled(true)
                } label: {
                    HStack {
                        Text(L10n.menuEnabled)
                        if monitor.isControlEnabled { Image(systemName: "checkmark") }
                    }
                }
                Button {
                    monitor.setControlEnabled(false)
                } label: {
                    HStack {
                        Text(L10n.menuDisabled)
                        if !monitor.isControlEnabled { Image(systemName: "checkmark") }
                    }
                }
            }

            Menu(L10n.menuLanguage) {
                ForEach(LanguagePreference.allCases) { preference in
                    Button {
                        selectLanguage(preference)
                    } label: {
                        HStack {
                            Text(languageTitle(preference))
                            if languageSettings.selection == preference {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                }
            }

            Divider()

            Button(L10n.menuDevices, action: showDevices)
                .disabled(!monitor.isControlEnabled)

            Divider()

            Button(L10n.menuQuit) {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
    }

    private func languageTitle(_ preference: LanguagePreference) -> String {
        switch preference {
        case .systemDefault:
            return L10n.languageSystemDefault(languageSettings.resolvedSystemLanguage == .korean
                ? L10n.languageKorean : L10n.languageEnglish)
        case .english: return L10n.languageEnglish
        case .korean: return L10n.languageKorean
        }
    }

}
