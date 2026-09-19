import Foundation

/// Explicit bundle lookup also covers AppKit and String-valued SwiftUI labels.
/// The process language is frozen before any UI or persisted error is created.
@MainActor
enum L10n {
    static var languageRestartFailed: String {
        String(localized: "language.restartFailed", defaultValue: "Natural Scrolling Switcher could not restart. Your language setting has not changed.", bundle: bundle, locale: locale)
    }

    static var menuLanguage: String {
        String(localized: "menu.language", defaultValue: "Language", bundle: bundle, locale: locale)
    }

    static let language = LanguagePreference.load(from: .standard).resolve()
    static let locale = Locale(identifier: language.rawValue)
    static let bundle = localizedBundle(in: .main, language: language)

    static func localizedBundle(in bundle: Bundle, language: AppLanguage) -> Bundle {
        guard let path = bundle.path(forResource: language.rawValue, ofType: "lproj"),
              let localized = Bundle(path: path) else { return bundle }
        return localized
    }

    static var menuAbout: String {
        String(localized: "menu.about", defaultValue: "About NSS", bundle: bundle, locale: locale)
    }

    static var appName: String {
        String(localized: "app.name", defaultValue: "Natural Scrolling Switcher", bundle: bundle, locale: locale)
    }

    static var menuMouseConnected: String {
        String(localized: "menu.mouseConnected", defaultValue: "Mouse connected", bundle: bundle, locale: locale)
    }

    static var menuTrackpadOnly: String {
        String(localized: "menu.trackpadOnly", defaultValue: "Trackpad only", bundle: bundle, locale: locale)
    }

    static var menuControlDisabled: String {
        String(localized: "menu.controlDisabled", defaultValue: "NSS control: Disabled", bundle: bundle, locale: locale)
    }

    static var menuScrollingOn: String {
        String(localized: "menu.scrollingOn", defaultValue: "Natural Scrolling: ON", bundle: bundle, locale: locale)
    }

    static var menuScrollingOff: String {
        String(localized: "menu.scrollingOff", defaultValue: "Natural Scrolling: OFF", bundle: bundle, locale: locale)
    }

    static var menuLaunchAtLogin: String {
        String(localized: "menu.launchAtLogin", defaultValue: "Launch at login", bundle: bundle, locale: locale)
    }

    static var menuNaturalScrolling: String {
        String(localized: "menu.naturalScrolling", defaultValue: "NSS Control", bundle: bundle, locale: locale)
    }

    static var menuEnabled: String {
        String(localized: "menu.enabled", defaultValue: "Enabled", bundle: bundle, locale: locale)
    }

    static var menuDisabled: String {
        String(localized: "menu.disabled", defaultValue: "Disabled", bundle: bundle, locale: locale)
    }

    static var menuDevices: String {
        String(localized: "menu.devices", defaultValue: "Devices…", bundle: bundle, locale: locale)
    }

    static var menuQuit: String {
        String(localized: "menu.quit", defaultValue: "Quit Natural Scrolling Switcher", bundle: bundle, locale: locale)
    }

    static var devicesTitle: String {
        String(localized: "devices.title", defaultValue: "Devices", bundle: bundle, locale: locale)
    }

    static var aboutTitle: String {
        String(localized: "about.title", defaultValue: "About Natural Scrolling Switcher", bundle: bundle, locale: locale)
    }

    static var aboutDescription: String {
        String(localized: "about.description", defaultValue: "A macOS utility that automatically switches Natural Scrolling depending on the connected input device.", bundle: bundle, locale: locale)
    }

    static var aboutCreator: String {
        String(localized: "about.creator", defaultValue: "Created by Akeri", bundle: bundle, locale: locale)
    }

    static var buttonClose: String {
        String(localized: "button.close", defaultValue: "Close", bundle: bundle, locale: locale)
    }

    static var devicesPriorityExplanation: String {
        String(localized: "devices.priorityExplanation", defaultValue: "macOS uses one scroll direction for all devices. The last edited connected mouse takes priority.", bundle: bundle, locale: locale)
    }

    static var devicesDisconnectExplanation: String {
        String(localized: "devices.disconnectExplanation", defaultValue: "When it disconnects, the latest connected mouse takes over. Auto follows external mouse presence.", bundle: bundle, locale: locale)
    }

    static var devicesShowInternal: String {
        String(localized: "devices.showInternal", defaultValue: "Show internal devices", bundle: bundle, locale: locale)
    }

    static var devicesEmpty: String {
        String(localized: "devices.empty", defaultValue: "No saved or connected external devices.", bundle: bundle, locale: locale)
    }

    static var devicesUnknownDevice: String {
        String(localized: "devices.unknownDevice", defaultValue: "Unknown Device", bundle: bundle, locale: locale)
    }

    static var devicesUnknownManufacturer: String {
        String(localized: "devices.unknownManufacturer", defaultValue: "Unknown manufacturer", bundle: bundle, locale: locale)
    }

    static var devicesUnknownTransport: String {
        String(localized: "devices.unknownTransport", defaultValue: "Unknown transport", bundle: bundle, locale: locale)
    }

    static var devicesMode: String {
        String(localized: "devices.mode", defaultValue: "Mode", bundle: bundle, locale: locale)
    }

    static var devicesModeAuto: String {
        String(localized: "devices.mode.auto", defaultValue: "Auto", bundle: bundle, locale: locale)
    }

    static var devicesModeManual: String {
        String(localized: "devices.mode.manual", defaultValue: "Manual", bundle: bundle, locale: locale)
    }

    static func devicesModeAccessibility(_ deviceName: String) -> String {
        String(localized: "devices.modeAccessibility", defaultValue: "Mode for \(deviceName)", bundle: bundle, locale: locale)
    }

    static var devicesManualDirection: String {
        String(localized: "devices.manualDirection", defaultValue: "Manual Direction", bundle: bundle, locale: locale)
    }

    static var devicesDirectionNatural: String {
        String(localized: "devices.direction.natural", defaultValue: "Natural", bundle: bundle, locale: locale)
    }

    static var devicesDirectionClassic: String {
        String(localized: "devices.direction.classic", defaultValue: "Classic", bundle: bundle, locale: locale)
    }

    static func devicesDirectionAccessibility(_ deviceName: String) -> String {
        String(localized: "devices.directionAccessibility", defaultValue: "Manual Direction for \(deviceName)", bundle: bundle, locale: locale)
    }

    static func devicesVendorProduct(_ vendorID: String, _ productID: String) -> String {
        String(localized: "devices.vendorProduct", defaultValue: "Vendor ID: \(vendorID) Product ID: \(productID)", bundle: bundle, locale: locale)
    }

    static var devicesUnknownID: String {
        String(localized: "devices.unknownID", defaultValue: "Unknown", bundle: bundle, locale: locale)
    }

    static var devicesInternal: String {
        String(localized: "devices.internal", defaultValue: "Internal device · excluded from Auto detection", bundle: bundle, locale: locale)
    }

    static var devicesStatusConnected: String {
        String(localized: "devices.status.connected", defaultValue: "Connected", bundle: bundle, locale: locale)
    }

    static var devicesStatusDisconnected: String {
        String(localized: "devices.status.disconnected", defaultValue: "Disconnected", bundle: bundle, locale: locale)
    }

    static var devicesForget: String {
        String(localized: "devices.forget", defaultValue: "Forget Device", bundle: bundle, locale: locale)
    }

    static var devicesIdentityAmbiguous: String {
        String(localized: "devices.identity.ambiguous", defaultValue: "Ambiguous identity · automatic matching is blocked. Saved policy is retained.", bundle: bundle, locale: locale)
    }

    static var devicesIdentityHighConfidence: String {
        String(localized: "devices.identity.highConfidence", defaultValue: "High confidence · serial or unique identifier", bundle: bundle, locale: locale)
    }

    static var devicesIdentityMediumConfidence: String {
        String(localized: "devices.identity.mediumConfidence", defaultValue: "Medium confidence · model fingerprint. Identical devices may be indistinguishable.", bundle: bundle, locale: locale)
    }

    static var devicesIdentitySessionOnly: String {
        String(localized: "devices.identity.sessionOnly", defaultValue: "Session only · saved device remains listed, but cannot be matched automatically after disconnect.", bundle: bundle, locale: locale)
    }

    static var devicesErrorRead: String {
        String(localized: "devices.error.read", defaultValue: "Saved devices could not be read. Existing data has been preserved.", bundle: bundle, locale: locale)
    }

    static var devicesErrorWrite: String {
        String(localized: "devices.error.write", defaultValue: "Saved devices could not be written.", bundle: bundle, locale: locale)
    }

    static func languageSystemDefault(_ resolvedLanguage: String) -> String {
        String(localized: "language.systemDefault", defaultValue: "System Default (\(resolvedLanguage))", bundle: bundle, locale: locale)
    }

    static var languageEnglish: String {
        String(localized: "language.english", defaultValue: "English", bundle: bundle, locale: locale)
    }

    static var languageKorean: String {
        String(localized: "language.korean", defaultValue: "한국어", bundle: bundle, locale: locale)
    }

    static var languageChangeTitle: String {
        String(localized: "language.changeTitle", defaultValue: "Change Language", bundle: bundle, locale: locale)
    }

    static var languageChangeMessage: String {
        String(localized: "language.changeMessage", defaultValue: "Natural Scrolling Switcher needs to restart to apply the new language.", bundle: bundle, locale: locale)
    }

    static var buttonCancel: String {
        String(localized: "button.cancel", defaultValue: "Cancel", bundle: bundle, locale: locale)
    }

    static var buttonRestart: String {
        String(localized: "button.restart", defaultValue: "Restart", bundle: bundle, locale: locale)
    }

}
