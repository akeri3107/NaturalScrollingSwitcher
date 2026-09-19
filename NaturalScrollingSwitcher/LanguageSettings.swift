import Foundation
import Combine

enum AppLanguage: String, CaseIterable {
    case english = "en"
    case korean = "ko"

    static func systemDefault(preferences: [String] = Locale.preferredLanguages) -> AppLanguage {
        // Foundation matches regional variants and skips unsupported preferences.
        let supported = [AppLanguage.english.rawValue, AppLanguage.korean.rawValue]
        let resolved = Bundle.preferredLocalizations(from: supported, forPreferences: preferences).first
        return AppLanguage(rawValue: resolved ?? "en") ?? .english
    }
}

enum LanguagePreference: String, CaseIterable, Identifiable {
    case systemDefault, english, korean
    static let defaultsKey = "appLanguagePreference"
    var id: String { rawValue }

    static func load(from defaults: UserDefaults) -> LanguagePreference {
        LanguagePreference(rawValue: defaults.string(forKey: defaultsKey) ?? "") ?? .systemDefault
    }

    func resolve(preferences: [String] = Locale.preferredLanguages) -> AppLanguage {
        switch self {
        case .systemDefault: return AppLanguage.systemDefault(preferences: preferences)
        case .english: return .english
        case .korean: return .korean
        }
    }
}

@MainActor
final class LanguageSettings: ObservableObject {
    enum SelectionResult { case cancelled, saved, restart }

    @Published private(set) var selection: LanguagePreference
    let appliedLanguage: AppLanguage
    private let defaults: UserDefaults
    private let systemPreferences: () -> [String]

    init(defaults: UserDefaults = .standard,
         systemPreferences: @escaping () -> [String] = { Locale.preferredLanguages }) {
        self.defaults = defaults
        self.systemPreferences = systemPreferences
        let selection = LanguagePreference.load(from: defaults)
        self.selection = selection
        appliedLanguage = selection.resolve(preferences: systemPreferences())
    }

    var resolvedSystemLanguage: AppLanguage {
        AppLanguage.systemDefault(preferences: systemPreferences())
    }

    /// Confirmation runs before any mutation. The displayed language stays fixed
    /// for this process, even when a same-language preference is saved immediately.
    func select(_ proposed: LanguagePreference, confirm: @MainActor () -> Bool,
                prepareRelaunch: @MainActor () throws -> Void) throws -> SelectionResult {
        let requiresRestart = proposed.resolve(preferences: systemPreferences()) != appliedLanguage
        guard requiresRestart || proposed != selection else { return .saved }
        if requiresRestart && !confirm() { return .cancelled }

        let previousValue = defaults.object(forKey: LanguagePreference.defaultsKey)
        defaults.set(proposed.rawValue, forKey: LanguagePreference.defaultsKey)
        do {
            // The new process must see the preference before the old process exits.
            guard defaults.synchronize() else { throw CocoaError(.fileWriteUnknown) }
            if requiresRestart { try prepareRelaunch() }
        } catch {
            if let previousValue {
                defaults.set(previousValue, forKey: LanguagePreference.defaultsKey)
            } else {
                defaults.removeObject(forKey: LanguagePreference.defaultsKey)
            }
            defaults.synchronize()
            throw error
        }
        selection = proposed
        return requiresRestart ? .restart : .saved
    }
}
