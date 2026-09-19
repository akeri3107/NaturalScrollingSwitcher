import Foundation

/// Run inside an isolated test .app containing the built en/ko resources.
/// This executable does not initialize NSApplication or touch scroll settings.
@main
struct LocalizationRuntimeTests {
    @MainActor static func main() throws {
        let defaults = UserDefaults.standard
        let action = CommandLine.arguments[1]
        if action == "clear" {
            defaults.removePersistentDomain(forName: Bundle.main.bundleIdentifier!)
            precondition(defaults.synchronize())
            return
        }
        if action == "save-en" || action == "save-ko" {
            let settings = LanguageSettings()
            _ = try settings.select(action == "save-en" ? .english : .korean,
                                    confirm: { true }, prepareRelaunch: {})
            return
        }
        let korean = action == "check-ko"
        let settings = LanguageSettings()
        precondition(L10n.language == (korean ? .korean : .english))
        precondition(settings.appliedLanguage == L10n.language)
        precondition(L10n.appName == "Natural Scrolling Switcher")
        precondition(L10n.menuLanguage == (korean ? "언어(Language)" : "Language"))
        precondition(L10n.menuDevices == (korean ? "장치…" : "Devices…"))
        precondition(L10n.devicesTitle == (korean ? "장치" : "Devices"))
        precondition(L10n.aboutTitle == (korean ? "Natural Scrolling Switcher 정보" : "About Natural Scrolling Switcher"))
        precondition(DeviceMode.auto.title == (korean ? "자동" : "Auto"))
        precondition(ManualDirection.natural.title == (korean ? "자연스러운 스크롤" : "Natural"))
        precondition(L10n.devicesModeAccessibility("Mouse") == (korean ? "Mouse의 모드" : "Mode for Mouse"))
        precondition(L10n.devicesDirectionAccessibility("Mouse") == (korean ? "Mouse 스크롤 방향 (수동)" : "Manual Direction for Mouse"))
        precondition(L10n.devicesVendorProduct("0x0001", "0x0002") == "Vendor ID: 0x0001 Product ID: 0x0002")
        precondition(L10n.devicesErrorWrite == (korean ? "장치 정보를 저장할 수 없습니다." : "Saved devices could not be written."))
        precondition(L10n.languageChangeTitle == (korean ? "언어 변경" : "Change Language"))
        precondition(L10n.buttonCancel == (korean ? "취소" : "Cancel"))
        precondition(L10n.buttonRestart == (korean ? "재시작" : "Restart"))
        print("PASS: process-start localization, enum titles, window titles, accessibility, errors: \(L10n.language.rawValue)")
    }
}
