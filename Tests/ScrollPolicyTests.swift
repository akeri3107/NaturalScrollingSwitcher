import Foundation

@main
struct ScrollPolicyTests {
    @MainActor static func main() {
        if CommandLine.arguments.count == 3 {
            let phase = CommandLine.arguments[1]
            let suite = CommandLine.arguments[2]
            let defaults = UserDefaults(suiteName: suite)!
            var calls = 0
            let monitor = ScrollMonitor(defaults: defaults, applyScrolling: { _ in calls += 1 })
            let enabled = phase.hasSuffix("enabled")
            if phase.hasPrefix("write-") {
                monitor.setControlEnabled(enabled)
                precondition(defaults.synchronize())
            } else {
                precondition(phase == "read-enabled" || phase == "read-disabled")
                precondition(monitor.isControlEnabled == enabled)
                monitor.start()
                precondition(enabled ? calls == 1 : calls == 0)
                monitor.stop()
                defaults.removePersistentDomain(forName: suite)
            }
            print("PASS: separate-process control restoration \(phase)")
            return
        }
        let suite = "NSS.ScrollPolicyTests.\(UUID().uuidString)"
        let defaults = UserDefaults(suiteName: suite)!
        defer { defaults.removePersistentDomain(forName: suite) }
        let store = DevicePolicyStore(defaults: defaults)
        var applied: [Bool] = []
        let verifySystem = CommandLine.arguments.contains("--system")
        let systemManager = ScrollManager()
        func readSystemDirection() -> Bool? {
            let process = Process()
            process.executableURL = URL(fileURLWithPath: "/usr/bin/defaults")
            process.arguments = ["read", "-g", "com.apple.swipescrolldirection"]
            let pipe = Pipe()
            process.standardOutput = pipe
            try! process.run()
            let data = pipe.fileHandleForReading.readDataToEndOfFile()
            process.waitUntilExit()
            guard process.terminationStatus == 0,
                  let value = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines),
                  value == "0" || value == "1" else { return nil }
            return value == "1"
        }
        let original = verifySystem ? readSystemDirection() : nil
        precondition(!verifySystem || original != nil)
        var systemMatches = true
        defer {
            if let original {
                systemManager.setNaturalScrolling(original)
                precondition(readSystemDirection() == original)
            }
        }
        let monitor = ScrollMonitor(policyStore: store, defaults: defaults, applyScrolling: {
            applied.append($0)
            if verifySystem {
                systemManager.setNaturalScrolling($0)
                systemMatches = systemMatches && readSystemDirection() == $0
            }
        })
        func device(_ id: UInt64, _ serial: String = "A", internalDevice: Bool = false) -> PointingDevice {
            PointingDevice(id: .registryEntry(id), productName: internalDevice ? "Apple Internal Keyboard / Trackpad" : "Mouse",
                manufacturer: "Test", vendorID: 1, productID: 2, transport: "Bluetooth", serialNumber: serial,
                uniqueID: nil, locationID: nil, primaryUsagePage: 1, primaryUsage: 2)
        }
        func update(_ devices: PointingDevice...) {
            store.updateDevices(Dictionary(uniqueKeysWithValues: devices.map { ($0.id, $0) }))
        }
        let a = device(1), b = device(2, "B"), c = device(3, "C"), internalDevice = device(4, "I", internalDevice: true)
        let natural = DevicePolicy(mode: .manual, manualDirection: .natural)
        let classic = DevicePolicy(mode: .manual, manualDirection: .classic)
        monitor.start()
        update()
        precondition(applied.last == true)
        update(a)
        precondition(applied.last == false && monitor.mouseConnected)
        store.setPolicy(natural, for: a)
        precondition(applied.last == true && monitor.naturalScrollingEnabled)
        store.setPolicy(classic, for: a)
        precondition(applied.last == false)
        store.setPolicy(natural, for: a)
        store.setPolicy(DevicePolicy(), for: a)
        precondition(applied.last == false)
        let count = applied.count
        update(a)
        precondition(applied.count == count)
        store.setPolicy(natural, for: a)
        update(a, b) // A's explicit edit remains preferred over a new B connection.
        precondition(applied.last == true)
        store.setPolicy(classic, for: b)
        precondition(applied.last == false)
        store.setPolicy(natural, for: a)
        update(a, b, c)
        precondition(applied.last == true)
        update(b, c) // Preferred A removed: latest connection C (Auto) wins.
        precondition(applied.last == false)
        store.setPolicy(natural, for: b)
        precondition(applied.last == true)
        let storedBeforeDisable = defaults.data(forKey: DevicePolicyStore.defaultsKey)
        let beforeDisable = applied.count
        let systemBeforeDisable = verifySystem ? readSystemDirection() : nil
        monitor.setControlEnabled(false)
        precondition(!monitor.isControlEnabled && applied.count == beforeDisable)
        precondition(defaults.data(forKey: DevicePolicyStore.defaultsKey) == storedBeforeDisable)
        update()
        update(b)
        store.setPolicy(classic, for: b)
        precondition(applied.count == beforeDisable && !monitor.isControlEnabled)
        if verifySystem { precondition(readSystemDirection() == systemBeforeDisable) }
        monitor.setControlEnabled(true)
        precondition(applied.count == beforeDisable + 1 && applied.last == false)
        let beforeSameDirection = applied.count
        monitor.setControlEnabled(false)
        monitor.setControlEnabled(true)
        precondition(applied.count == beforeSameDirection + 1 && applied.last == false)
        precondition(defaults.bool(forKey: ScrollMonitor.controlEnabledDefaultsKey))
        update()
        let beforeOfflineEdit = applied.count
        let offlineB = store.rows.first { $0.id == .known(store.knownDevices.first { $0.identity?.source == .serialNumber("B") }!.id) }!
        store.setPolicy(classic, for: offlineB)
        precondition(applied.count == beforeOfflineEdit)
        let reconnectedB = device(100, "B")
        update(reconnectedB)
        precondition(applied.last == false && store.policy(for: reconnectedB) == classic)
        update(reconnectedB, internalDevice)
        store.setPolicy(natural, for: internalDevice)
        precondition(applied.last == false) // Internal rows never take priority.
        store.setPolicy(natural, for: reconnectedB)
        update(reconnectedB, device(101, "B")) // Ambiguous identity cannot apply a saved manual policy.
        precondition(applied.last == false)
        update()
        precondition(applied.last == true)
        monitor.stop()
        let stoppedCount = applied.count
        update(a)
        store.setPolicy(classic, for: a)
        precondition(applied.count == stoppedCount)
        // Restore global state independently from per-device data, including startup.
        for legacy in ["automatic", "on", "off", "unknown", "absent"] {
            let migrationSuite = "NSS.ControlMigration.\(UUID().uuidString)"
            let migrationDefaults = UserDefaults(suiteName: migrationSuite)!
            if legacy != "absent" { migrationDefaults.set(legacy, forKey: "naturalScrollingMode") }
            var startupCalls: [Bool] = []
            let migrated = ScrollMonitor(defaults: migrationDefaults, applyScrolling: { startupCalls.append($0) })
            let expectedEnabled = legacy != "on" && legacy != "off"
            precondition(migrated.isControlEnabled == expectedEnabled)
            precondition(migrationDefaults.object(forKey: "naturalScrollingMode") == nil)
            precondition(startupCalls.isEmpty)
            migrated.start()
            precondition(expectedEnabled ? startupCalls.count == 1 : startupCalls.isEmpty)
            migrated.stop()
            migrated.setControlEnabled(false)
            let disabledRestore = ScrollMonitor(defaults: migrationDefaults, applyScrolling: { _ in
                preconditionFailure("Restored Disabled must never apply scrolling")
            })
            disabledRestore.start()
            precondition(!disabledRestore.isControlEnabled)
            disabledRestore.stop()
            migrated.setControlEnabled(true)
            let enabledRestore = ScrollMonitor(defaults: migrationDefaults, applyScrolling: { _ in })
            precondition(enabledRestore.isControlEnabled)
            migrationDefaults.removePersistentDomain(forName: migrationSuite)
        }
        precondition(systemMatches)
        print("PASS: immediate Natural/Classic/Auto application, Enabled/Disabled gating, re-enable cache reset, last-edit priority, disconnect fallback, offline edits, reconnect restoration, ambiguity, internal exclusion, deduplication, stop")
    }
}
