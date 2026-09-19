// Run with swiftc using PointingDevice.swift and MouseDetector.swift (see Tests/README.md).
import Foundation

@main
struct DeviceIdentityTests {
    @MainActor
    static func main() {
        func device(
            _ id: DeviceIdentifier,
            name: String? = "Same Model",
            serial: String? = "shared-serial",
            unique: String? = "unique",
            location: UInt32? = 42
        ) -> PointingDevice {
            PointingDevice(
                id: id, productName: name, manufacturer: nil,
                vendorID: 123, productID: 456, transport: "USB",
                serialNumber: serial, uniqueID: unique, locationID: location,
                primaryUsagePage: 1, primaryUsage: 2
            )
        }

        let first = device(.registryEntry(1))
        let second = device(.registryEntry(2))
        precondition(first.id != second.id)
        precondition(first.identityHint == second.identityHint)
        precondition(first.identityHint?.source == .serialNumber("shared-serial"))
        precondition(device(.registryEntry(3), serial: " ").identityHint?.source == .uniqueID("unique"))
        precondition(device(.registryEntry(3), serial: nil, unique: nil).identityHint?.source == .location(42))
        precondition(device(.registryEntry(3), serial: nil, unique: nil, location: 0).identityHint == nil)
        precondition(device(.registryEntry(3), serial: nil, unique: nil, location: nil).identityHint == nil)

        let internalDevice = device(.registryEntry(4), name: "Apple Internal Keyboard / Trackpad")
        var collection = PointingDeviceCollection()
        collection.add(internalDevice)
        precondition(!collection.mouseConnected)
        collection.add(first)
        collection.add(second)
        collection.add(first) // Initial enumeration followed by matching callback.
        precondition(collection.devices.count == 3 && collection.mouseConnected)
        collection.remove(first.id)
        collection.remove(first.id) // Duplicate removal must not remove another mouse.
        precondition(collection.devices.count == 2 && collection.mouseConnected)
        precondition(collection.devices[second.id] == second)
        collection.remove(second.id)
        precondition(collection.devices.count == 1 && !collection.mouseConnected)

        let reconnected = device(.registryEntry(5))
        precondition(reconnected.identityHint == first.identityHint)
        collection.add(reconnected)
        collection.remove(first.id) // A stale removal cannot delete a new connection.
        precondition(collection.devices[reconnected.id] == reconnected)
        let fallbackA = device(.session(UUID()), name: nil, serial: nil, unique: nil, location: nil)
        let fallbackB = device(.session(UUID()), name: nil, serial: nil, unique: nil, location: nil)
        precondition(fallbackA.id != fallbackB.id && fallbackA.isExternalMouse)
        collection.add(fallbackA)
        collection.add(fallbackB)
        precondition(collection.devices.count == 4)
        collection.removeAll()
        precondition(collection.devices.isEmpty && !collection.mouseConnected)

        // Read-only integration check against connected hardware. No device open,
        // input access request, or system scroll setting change.
        let detector = MouseDetector()
        var reports: [Bool] = []
        detector.start { reports.append($0) }
        let snapshot = detector.connectedDevices
        precondition(reports == [snapshot.values.contains { $0.isExternalMouse }])
        for (key, value) in snapshot { precondition(key == value.id) }
        detector.start { _ in preconditionFailure("Duplicate start replaced handler") }
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        // Do not change physical devices during this short snapshot check.
        precondition(detector.connectedDevices == snapshot && reports.count == 1)
        detector.stop()
        precondition(detector.connectedDevices.isEmpty)
        detector.start { reports.append($0) }
        precondition(detector.connectedDevices == snapshot && reports.count == 2)
        detector.stop()
        print("PASS: identity collisions, missing properties, reconnect hints, individual removal, Auto aggregate, initial HID snapshot (\(snapshot.count) devices), duplicate callbacks, restart")
    }
}
