import Foundation

@main
struct DevicePolicyTests {
    @MainActor static func main() {
        func mouse(_ id: UInt64, serial: String? = nil, unique: String? = nil,
                   name: String? = "BT5.0 Mouse", maker: String? = "BEKEN",
                   location: UInt32? = 1) -> PointingDevice {
            PointingDevice(id: .registryEntry(id), productName: name, manufacturer: maker,
                vendorID: 9639, productID: 1, transport: "Bluetooth Low Energy",
                serialNumber: serial, uniqueID: unique, locationID: location,
                primaryUsagePage: 1, primaryUsage: 2)
        }
        func snapshot(_ values: PointingDevice...) -> [DeviceIdentifier: PointingDevice] {
            Dictionary(uniqueKeysWithValues: values.map { ($0.id, $0) })
        }
        if CommandLine.arguments.count == 3 {
            let phase = CommandLine.arguments[1]
            let suite = CommandLine.arguments[2]
            let defaults = UserDefaults(suiteName: suite)!
            let store = DevicePolicyStore(defaults: defaults)
            if phase == "write" {
                let device = mouse(100)
                store.updateDevices(snapshot(device))
                store.setPolicy(DevicePolicy(mode: .manual, manualDirection: .classic), for: device)
                store.updateDevices([:])
                precondition(store.rows.count == 1 && !store.rows[0].connected)
                precondition(defaults.synchronize())
            } else {
                precondition(phase == "read")
                precondition(store.rows.count == 1 && !store.rows[0].connected && store.rows[0].policy == DevicePolicy(mode: .manual, manualDirection: .classic))
                let reconnected = mouse(200, location: 999)
                store.updateDevices(snapshot(reconnected))
                precondition(store.policy(for: reconnected) == DevicePolicy(mode: .manual, manualDirection: .classic) && store.rows[0].connected)
                defaults.removePersistentDomain(forName: suite)
            }
            print("PASS: separate-process medium fingerprint persistence \(phase)")
            return
        }
        let suite = "NSS.KnownTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DevicePolicyStore(defaults: defaults)
        let original = mouse(1)
        let reconnected = mouse(2, location: 999)
        precondition(original.identityHint == reconnected.identityHint)
        precondition(original.identityHint?.confidence == .medium)
        precondition(mouse(3, serial: "serial").identityHint?.confidence == .high)
        precondition(mouse(3, unique: "unique").identityHint?.confidence == .high)
        store.updateDevices(snapshot(original))
        precondition(store.knownDevices.isEmpty && store.rows.count == 1)
        store.setPolicy(DevicePolicy(mode: .manual, manualDirection: .classic), for: original)
        let knownID = store.knownDevices[0].id
        precondition(store.rows[0].policy == DevicePolicy(mode: .manual, manualDirection: .classic) && store.rows[0].connected)
        store.updateDevices([:])
        precondition(store.rows.count == 1 && !store.rows[0].connected && store.rows[0].policy == DevicePolicy(mode: .manual, manualDirection: .classic))
        store.updateDevices(snapshot(reconnected))
        precondition(store.knownDevices[0].id == knownID && store.rows.count == 1)
        precondition(store.rows[0].connected && store.policy(for: reconnected) == DevicePolicy(mode: .manual, manualDirection: .classic))
        store.forgetDevice(knownID) // Connected records cannot be forgotten.
        precondition(store.knownDevices.count == 1)
        let restored = DevicePolicyStore(defaults: defaults)
        precondition(restored.rows.count == 1 && !restored.rows[0].connected)
        restored.updateDevices(snapshot(reconnected))
        precondition(restored.policy(for: reconnected) == DevicePolicy(mode: .manual, manualDirection: .classic))

        // Simultaneous identical fingerprints must detach all automatic bindings.
        restored.updateDevices(snapshot(original, reconnected))
        precondition(restored.rows.count == 3 && restored.rows.allSatisfy(\.ambiguous))
        precondition(restored.policy(for: original) == DevicePolicy() && restored.policy(for: reconnected) == DevicePolicy())
        precondition(restored.knownDevices[0].policy == DevicePolicy(mode: .manual, manualDirection: .classic))
        restored.setPolicy(DevicePolicy(), for: original)
        precondition(restored.knownDevices.count == 1)
        restored.updateDevices(snapshot(reconnected))
        precondition(restored.policy(for: reconnected) == DevicePolicy())
        let quarantined = DevicePolicyStore(defaults: defaults)
        quarantined.updateDevices(snapshot(original))
        precondition(quarantined.policy(for: original) == DevicePolicy())
        quarantined.forgetDevice(knownID)
        precondition(quarantined.knownDevices.isEmpty)
        precondition(DevicePolicyStore(defaults: defaults).knownDevices.isEmpty)

        // Missing fingerprint fields: persist an offline record but never guess a reconnection.
        let incomplete = mouse(4, maker: nil)
        let incompleteAgain = mouse(5, maker: nil)
        quarantined.updateDevices(snapshot(incomplete))
        quarantined.setPolicy(DevicePolicy(mode: .manual, manualDirection: .natural), for: incomplete)
        precondition(quarantined.knownDevices[0].identity == nil)
        quarantined.updateDevices([:])
        precondition(quarantined.rows.count == 1 && !quarantined.rows[0].connected)
        quarantined.updateDevices(snapshot(incompleteAgain))
        precondition(quarantined.rows.count == 2 && quarantined.policy(for: incompleteAgain) == DevicePolicy())
        let archiveText = String(data: defaults.data(forKey: DevicePolicyStore.defaultsKey)!, encoding: .utf8)!
        precondition(!archiveText.contains("registryEntry") && !archiveText.contains("location"))

        // High-confidence IDs with changed descriptive data must not be reused.
        let high = mouse(6, serial: "high")
        quarantined.updateDevices(snapshot(high))
        quarantined.setPolicy(DevicePolicy(), for: high)
        let changed = mouse(7, serial: "high", name: "Different model")
        quarantined.updateDevices(snapshot(changed))
        precondition(quarantined.policy(for: changed) == DevicePolicy())

        // Decode all legacy choices and ensure v3 encoding is structured.
        for (raw, expected) in [
            ("followAuto", DevicePolicy()), ("ignore", DevicePolicy()),
            ("natural", DevicePolicy(mode: .manual, manualDirection: .natural)),
            ("classic", DevicePolicy(mode: .manual, manualDirection: .classic))
        ] {
            let decoded = try! JSONDecoder().decode(DevicePolicy.self, from: JSONEncoder().encode(raw))
            precondition(decoded == expected)
            let encoded = try! JSONEncoder().encode(decoded)
            precondition(String(data: encoded, encoding: .utf8)!.contains("manualDirection"))
        }
        let inactiveDirection = DevicePolicy(mode: .auto, manualDirection: .natural)
        precondition(try! JSONDecoder().decode(DevicePolicy.self, from: JSONEncoder().encode(inactiveDirection)) == inactiveDirection)

        // v1 migration preserves policy and its offline representation.
        defaults.removePersistentDomain(forName: suite)
        let legacy = Data(#"{"version":1,"records":[{"hint":{"vendorID":9639,"productID":1,"transport":"Bluetooth Low Energy","source":{"serialNumber":{"_0":"legacy"}}},"signature":{"productName":"BT5.0 Mouse","manufacturer":"BEKEN","usagePage":1,"usage":2},"policy":"classic"}],"blockedHints":[]}"#.utf8)
        defaults.set(legacy, forKey: DevicePolicyStore.legacyDefaultsKey)
        let migrated = DevicePolicyStore(defaults: defaults)
        precondition(migrated.storageError == nil && migrated.knownDevices.count == 1)
        precondition(migrated.rows[0].policy == DevicePolicy(mode: .manual, manualDirection: .classic) && !migrated.rows[0].connected)
        let legacyMouse = mouse(8, serial: "legacy")
        migrated.updateDevices(snapshot(legacyMouse))
        precondition(migrated.policy(for: legacyMouse) == DevicePolicy(mode: .manual, manualDirection: .classic))
        migrated.updateDevices([:])
        migrated.forgetDevice(migrated.knownDevices[0].id)
        precondition(DevicePolicyStore(defaults: defaults).knownDevices.isEmpty) // No reimport of v1.
        defaults.removePersistentDomain(forName: suite)
        let migratedIDs = [UUID(), UUID(), UUID(), UUID()]
        let fixtureRecords: [[String: Any]] = zip(migratedIDs, ["followAuto", "natural", "classic", "ignore"]).map { id, policy in
            ["id": id.uuidString, "details": ["productName": "Legacy Mouse"], "policy": policy]
        }
        let v2 = try! JSONSerialization.data(withJSONObject: ["version": 2, "knownDevices": fixtureRecords, "blockedHints": []])
        defaults.set(v2, forKey: DevicePolicyStore.previousDefaultsKey)
        let migratedV2 = DevicePolicyStore(defaults: defaults)
        precondition(migratedV2.knownDevices.map(\.id) == migratedIDs)
        precondition(migratedV2.knownDevices.map(\.policy) == [DevicePolicy(), DevicePolicy(mode: .manual, manualDirection: .natural), DevicePolicy(mode: .manual, manualDirection: .classic), DevicePolicy()])
        precondition(defaults.data(forKey: DevicePolicyStore.defaultsKey) != nil)

        for data in [Data("broken".utf8), Data(#"{"version":99,"knownDevices":[],"blockedHints":[]}"#.utf8)] {
            defaults.set(data, forKey: DevicePolicyStore.defaultsKey)
            let invalid = DevicePolicyStore(defaults: defaults)
            invalid.updateDevices(snapshot(original))
            invalid.setPolicy(DevicePolicy(mode: .manual, manualDirection: .natural), for: original)
            precondition(invalid.storageError != nil)
            precondition(defaults.data(forKey: DevicePolicyStore.defaultsKey) == data)
        }
        print("PASS: Classic → Disconnected retained → changed-registry/location reconnect → Classic; restart, confidence, collisions, session-only retention, Forget, v1 migration, corrupt archive preservation")
    }
}
