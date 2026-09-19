import Foundation

@main
struct LocalizationTests {
    @MainActor static func main() throws {
        let suite = "NSS.LanguageTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        func make(_ preferences: [String]) -> LanguageSettings {
            LanguageSettings(defaults: defaults, systemPreferences: { preferences })
        }
        for (preferences, expected) in [(["en-US"], AppLanguage.english), (["ko-KR"], .korean),
                (["fr-FR", "ja-JP", "de-DE"], .english), (["fr-FR", "ko-KR"], .korean),
                ([String](), .english)] {
            precondition(make(preferences).selection == .systemDefault)
            precondition(make(preferences).appliedLanguage == expected)
            precondition(LanguagePreference.english.resolve(preferences: preferences) == .english)
            precondition(LanguagePreference.korean.resolve(preferences: preferences) == .korean)
        }
        let settings = make(["en-US"])
        var confirmations = 0
        var restarts = 0
        let unchanged = try settings.select(.english, confirm: { confirmations += 1; return true },
                                            prepareRelaunch: { restarts += 1 })
        precondition(unchanged == .saved && confirmations == 0 && restarts == 0)
        precondition(settings.selection == .english && make(["ko"]).appliedLanguage == .english)
        let oldData = defaults.dictionaryRepresentation()
        let cancelled = try settings.select(.korean, confirm: { confirmations += 1; return false },
                                            prepareRelaunch: { restarts += 1 })
        precondition(cancelled == .cancelled && restarts == 0 && settings.selection == .english)
        precondition(NSDictionary(dictionary: oldData).isEqual(to: defaults.dictionaryRepresentation()))
        let restarted = try settings.select(.korean, confirm: { true }, prepareRelaunch: {
            precondition(LanguagePreference.load(from: defaults) == .korean)
            restarts += 1
        })
        precondition(restarted == .restart && restarts == 1 && settings.appliedLanguage == .english)
        let korean = make(["en"])
        precondition(korean.selection == .korean && korean.appliedLanguage == .korean)
        enum FakeFailure: Error { case launch }
        do {
            _ = try korean.select(.english, confirm: { true }, prepareRelaunch: { throw FakeFailure.launch })
            preconditionFailure("A failed helper launch must throw")
        } catch FakeFailure.launch {}
        precondition(korean.selection == .korean && LanguagePreference.load(from: defaults) == .korean)
        let backToEnglish = try korean.select(.english, confirm: { true }, prepareRelaunch: {})
        precondition(backToEnglish == .restart)
        precondition(make(["ko"]).appliedLanguage == .english)
        _ = try make(["ko"]).select(.systemDefault, confirm: { true }, prepareRelaunch: {})
        precondition(make(["ko"]).selection == .systemDefault && make(["ko"]).appliedLanguage == .korean)
        // Other application settings and policy archives survive language selection.
        defaults.set(Data([1, 2, 3]), forKey: "devicePolicies.v3")
        defaults.set(false, forKey: "scrollControlEnabled")
        _ = try make(["en"]).select(.english, confirm: { true }, prepareRelaunch: {})
        precondition(defaults.data(forKey: "devicePolicies.v3") == Data([1, 2, 3]))
        precondition(!defaults.bool(forKey: "scrollControlEnabled"))
        defaults.set("invalid", forKey: LanguagePreference.defaultsKey)
        precondition(make(["en"]).selection == .systemDefault)
        print("PASS: system resolution, forced language, cancel, same-language save, restart, rollback, persistence")

        guard CommandLine.arguments.count == 3,
              let app = Bundle(path: CommandLine.arguments[1]) else {
            fatalError("Supply built app and source catalog paths")
        }
        let json = try JSONSerialization.jsonObject(with: Data(contentsOf: URL(fileURLWithPath: CommandLine.arguments[2]))) as! [String: Any]
        let strings = json["strings"] as! [String: [String: Any]]
        for language in AppLanguage.allCases {
            let bundle = L10n.localizedBundle(in: app, language: language)
            let locale = Locale(identifier: language.rawValue)
            for (key, entry) in strings {
                let localizations = entry["localizations"] as! [String: [String: Any]]
                let unit = localizations[language.rawValue]!["stringUnit"] as! [String: String]
                precondition(bundle.localizedString(forKey: key, value: nil, table: nil) == unit["value"], key)
            }
            let name = "Mouse %1$@ 🖱️"
            let mode = String(localized: "devices.modeAccessibility", defaultValue: "Mode for \(name)", bundle: bundle, locale: locale)
            let direction = String(localized: "devices.directionAccessibility", defaultValue: "Manual Direction for \(name)", bundle: bundle, locale: locale)
            let vendor = "0x1234", product = "0x5678"
            let ids = String(localized: "devices.vendorProduct", defaultValue: "Vendor ID: \(vendor) Product ID: \(product)", bundle: bundle, locale: locale)
            let resolved = language == .korean ? "한국어" : "English"
            let system = String(localized: "language.systemDefault", defaultValue: "System Default (\(resolved))", bundle: bundle, locale: locale)
            precondition(mode == (language == .korean ? "\(name)의 모드" : "Mode for \(name)"))
            precondition(direction == (language == .korean ? "\(name) 스크롤 방향 (수동)" : "Manual Direction for \(name)"))
            precondition(ids == "Vendor ID: 0x1234 Product ID: 0x5678")
            precondition(system == (language == .korean ? "시스템 기본값 (한국어)" : "System Default (English)"))
        }
        print("PASS: every compiled English/Korean catalog entry and Foundation interpolation")

        let child = Process()
        child.executableURL = URL(fileURLWithPath: "/bin/sleep")
        child.arguments = ["0.2"]
        try child.run()
        precondition(AppRelauncher.waitForExit(of: child.processIdentifier, timeout: .now() + 5))
        child.waitUntilExit()
        precondition(AppRelauncher.waitForExit(of: child.processIdentifier, timeout: .now() + 1))
        precondition(!AppRelauncher.waitForExit(of: ProcessInfo.processInfo.processIdentifier, timeout: .now() + 0.05))
        print("PASS: relaunch exit event, already-exited parent, cancelled-termination timeout")
    }
}
