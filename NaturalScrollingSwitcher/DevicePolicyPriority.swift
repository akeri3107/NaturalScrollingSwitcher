import Foundation

/// One system-wide setting: latest edited connected mouse wins until removed.
/// Otherwise use the latest connection. Startup batches have no observed arrival
/// order, so registry ID (then session UUID) provides a deterministic tie-break.
struct DevicePolicyPriority {
    private var connectionOrder: [DeviceIdentifier] = []
    private var preferredDevice: DeviceIdentifier?

    var selectedDevice: DeviceIdentifier? { preferredDevice ?? connectionOrder.last }

    mutating func updateDevices(_ devices: [PointingDevice]) {
        let connected = Set(devices.filter(\.isExternalMouse).map(\.id))
        connectionOrder.removeAll { !connected.contains($0) }
        let added = connected.subtracting(connectionOrder).sorted(by: Self.precedes)
        connectionOrder.append(contentsOf: added)
        if let preferredDevice, !connected.contains(preferredDevice) {
            self.preferredDevice = nil
        }
    }

    mutating func policyChanged(for id: DeviceIdentifier) {
        if connectionOrder.contains(id) { preferredDevice = id }
    }

    nonisolated private static func precedes(_ left: DeviceIdentifier, _ right: DeviceIdentifier) -> Bool {
        switch (left, right) {
        case (.registryEntry(let a), .registryEntry(let b)): return a < b
        case (.session(let a), .session(let b)): return a.uuidString < b.uuidString
        case (.registryEntry, .session): return true
        case (.session, .registryEntry): return false
        }
    }
}
