import Foundation

enum DeviceMode: String, Codable, CaseIterable, Identifiable {
    case auto, manual
    var id: String { rawValue }
    @MainActor var title: String { self == .auto ? L10n.devicesModeAuto : L10n.devicesModeManual }
}

enum ManualDirection: String, Codable, CaseIterable, Identifiable {
    case natural, classic
    var id: String { rawValue }
    @MainActor var title: String { self == .natural ? L10n.devicesDirectionNatural : L10n.devicesDirectionClassic }
    var naturalScrollingEnabled: Bool { self == .natural }
}

struct DevicePolicy: Codable, Equatable {
    var mode: DeviceMode = .auto
    var manualDirection: ManualDirection = .classic

    init(mode: DeviceMode = .auto, manualDirection: ManualDirection = .classic) {
        self.mode = mode
        self.manualDirection = manualDirection
    }

    private enum CodingKeys: String, CodingKey { case mode, manualDirection }

    init(from decoder: Decoder) throws {
        // v1/v2 stored a single policy string. Ignore now follows Auto.
        if let legacy = try? decoder.singleValueContainer().decode(String.self) {
            switch legacy {
            case "followAuto", "ignore": self.init()
            case "natural": self.init(mode: .manual, manualDirection: .natural)
            case "classic": self.init(mode: .manual, manualDirection: .classic)
            default:
                throw DecodingError.dataCorrupted(.init(codingPath: decoder.codingPath,
                                                        debugDescription: "Unknown legacy device policy"))
            }
        } else {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            self.init(mode: try container.decode(DeviceMode.self, forKey: .mode),
                      manualDirection: try container.decode(ManualDirection.self, forKey: .manualDirection))
        }
    }
}
