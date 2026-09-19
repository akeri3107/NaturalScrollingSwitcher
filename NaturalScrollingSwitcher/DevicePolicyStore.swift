import Foundation
import Combine

/// Stores preferences and reports completed changes. ScrollMonitor applies settings.
@MainActor
final class DevicePolicyStore: ObservableObject {
    static let defaultsKey = "devicePolicies.v3"
    static let previousDefaultsKey = "devicePolicies.v2"
    static let legacyDefaultsKey = "devicePolicies.v1"

    enum Change {
        case devicesUpdated
        case policyChanged(DeviceIdentifier?)
    }
    var onChange: ((Change) -> Void)?

    private struct Archive: Codable {
        let version: Int
        let knownDevices: [KnownDevice]
        let blockedHints: Set<DeviceIdentityHint>
    }

    private struct LegacyArchive: Codable {
        struct Signature: Codable {
            let productName: String?
            let manufacturer: String?
            let usagePage: UInt32?
            let usage: UInt32?
        }
        struct Record: Codable {
            let hint: DeviceIdentityHint
            let signature: Signature
            let policy: DevicePolicy
        }
        let version: Int
        let records: [Record]
        let blockedHints: Set<DeviceIdentityHint>
    }

    @Published private(set) var devices: [PointingDevice] = []
    @Published private(set) var knownDevices: [KnownDevice] = []
    @Published private(set) var rows: [DeviceRow] = []
    @Published private(set) var storageError: String?
    private var blockedHints = Set<DeviceIdentityHint>()
    // Live bindings are never serialized, including for session-only known devices.
    private var connections: [UUID: DeviceIdentifier] = [:]
    private let defaults: UserDefaults
    private var canWrite = true

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        do {
            let isV3 = defaults.object(forKey: Self.defaultsKey) != nil
            if let value = defaults.object(forKey: Self.defaultsKey) ?? defaults.object(forKey: Self.previousDefaultsKey) {
                guard let data = value as? Data else { throw ArchiveError.invalid }
                let archive = try JSONDecoder().decode(Archive.self, from: data)
                guard archive.version == (isV3 ? 3 : 2),
                      Set(archive.knownDevices.map(\.id)).count == archive.knownDevices.count,
                      archive.knownDevices.allSatisfy({ $0.identity?.confidence != .sessionOnly }) else {
                    throw ArchiveError.invalid
                }
                knownDevices = archive.knownDevices
                blockedHints = archive.blockedHints
                if !isV3 {
                    quarantineDuplicateRecords()
                    persist()
                }
            } else if let value = defaults.object(forKey: Self.legacyDefaultsKey) {
                guard let data = value as? Data else { throw ArchiveError.invalid }
                let legacy = try JSONDecoder().decode(LegacyArchive.self, from: data)
                guard legacy.version == 1 else { throw ArchiveError.invalid }
                blockedHints = Set(legacy.blockedHints.filter { $0.confidence != .sessionOnly })
                knownDevices = legacy.records.map { record in
                    KnownDevice(id: UUID(), identity: record.hint.confidence == .sessionOnly ? nil : record.hint,
                                details: DeviceDetails(productName: record.signature.productName,
                                    manufacturer: record.signature.manufacturer, transport: record.hint.transport,
                                    vendorID: record.hint.vendorID, productID: record.hint.productID,
                                    usagePage: record.signature.usagePage, usage: record.signature.usage),
                                policy: record.policy)
                }
                quarantineDuplicateRecords()
                persist() // Preserve the v1 archive as a migration backup.
            }
            quarantineDuplicateRecords()
        } catch {
            canWrite = false
            storageError = L10n.devicesErrorRead
        }
        rebuildRows()
    }

    private enum ArchiveError: Error { case invalid }

    private func identity(for device: PointingDevice) -> DeviceIdentityHint? {
        guard let hint = device.identityHint, hint.confidence != .sessionOnly else { return nil }
        return hint
    }

    private func quarantineDuplicateRecords() {
        var seen = Set<DeviceIdentityHint>()
        for known in knownDevices {
            if let hint = known.identity, !seen.insert(hint).inserted { blockedHints.insert(hint) }
        }
    }

    func updateDevices(_ connected: [DeviceIdentifier: PointingDevice]) {
        devices = Array(connected.values)
        let oldBlocked = blockedHints
        let pairs = devices.compactMap { device in identity(for: device).map { ($0, device) } }
        let groups = Dictionary(grouping: pairs, by: { $0.0 })
        for (hint, group) in groups {
            if group.count > 1 { blockedHints.insert(hint) }
            for known in knownDevices where known.identity == hint {
                if group.contains(where: { DeviceDetails($0.1) != known.details }) {
                    blockedHints.insert(hint)
                }
            }
        }
        quarantineDuplicateRecords()
        // Only explicit session-only bindings survive, and only while connected.
        connections = connections.filter { knownID, deviceID in
            connected[deviceID] != nil && knownDevices.contains { $0.id == knownID && $0.identity == nil }
        }
        for known in knownDevices {
            guard let hint = known.identity, !blockedHints.contains(hint),
                  let group = groups[hint], group.count == 1,
                  let device = group.first?.1, known.details == DeviceDetails(device) else { continue }
            connections[known.id] = device.id
        }
        if oldBlocked != blockedHints { persist() }
        rebuildRows()
        onChange?(.devicesUpdated)
    }

    func policy(for device: PointingDevice) -> DevicePolicy {
        guard let id = connections.first(where: { $0.value == device.id })?.key else { return DevicePolicy() }
        return knownDevices.first(where: { $0.id == id })?.policy ?? DevicePolicy()
    }

    func setPolicy(_ policy: DevicePolicy, for device: PointingDevice) {
        guard let live = devices.first(where: { $0.id == device.id }), canWrite else { return }
        if let hint = identity(for: live), blockedHints.contains(hint) { return }
        if let id = connections.first(where: { $0.value == live.id })?.key,
           let index = knownDevices.firstIndex(where: { $0.id == id }) {
            knownDevices[index].policy = policy
        } else {
            let known = KnownDevice(id: UUID(), identity: identity(for: live), details: DeviceDetails(live), policy: policy)
            knownDevices.append(known)
            connections[known.id] = live.id
        }
        persist()
        rebuildRows()
        onChange?(.policyChanged(live.id))
    }

    func setPolicy(_ policy: DevicePolicy, for row: DeviceRow) {
        switch row.id {
        case .known(let id):
            guard canWrite, let index = knownDevices.firstIndex(where: { $0.id == id }) else { return }
            knownDevices[index].policy = policy
            persist()
            rebuildRows()
            onChange?(.policyChanged(connections[id]))
        case .connected(let id):
            if let device = devices.first(where: { $0.id == id }) { setPolicy(policy, for: device) }
        }
    }

    func forgetDevice(_ id: UUID) {
        guard canWrite, connections[id] == nil else { return }
        knownDevices.removeAll { $0.id == id }
        // Do not erase collision evidence: forgetting is not proof of uniqueness.
        persist()
        rebuildRows()
    }

    private func rebuildRows() {
        var result = knownDevices.map { known in
            DeviceRow(id: .known(known.id), details: known.details, policy: known.policy,
                      connected: connections[known.id] != nil,
                      ambiguous: known.identity.map { blockedHints.contains($0) } ?? false,
                      confidence: known.confidence)
        }
        let assigned = Set(connections.values)
        for device in devices where !assigned.contains(device.id) {
            let hint = identity(for: device)
            result.append(DeviceRow(id: .connected(device.id), details: DeviceDetails(device), policy: DevicePolicy(),
                                    connected: true, ambiguous: hint.map { blockedHints.contains($0) } ?? false,
                                    confidence: hint?.confidence ?? .sessionOnly))
        }
        rows = result.sorted {
            let left = $0.details.productName ?? "Unknown Device"
            let right = $1.details.productName ?? "Unknown Device"
            return left == right ? String(describing: $0.id) < String(describing: $1.id) : left < right
        }
    }

    private func persist() {
        guard canWrite else { return }
        do {
            let archive = Archive(version: 3, knownDevices: knownDevices, blockedHints: blockedHints)
            defaults.set(try JSONEncoder().encode(archive), forKey: Self.defaultsKey)
            storageError = nil
        } catch {
            storageError = L10n.devicesErrorWrite
        }
    }
}
