import Foundation

/// Identifies one live HID registry entry, not a physical mouse across reconnects.
enum DeviceIdentifier: Hashable {
    case registryEntry(UInt64)
    case session(UUID)
}

/// A best-effort reconnect hint, never the key of the connected-device collection.
/// Firmware may omit or duplicate serials/unique IDs; locations can change with ports.
struct DeviceIdentityHint: Hashable, Codable {
    enum Source: Hashable, Codable {
        case serialNumber(String)
        case uniqueID(String)
        case fingerprint(manufacturer: String, productName: String)
        case location(UInt32)
    }

    let vendorID: UInt32?
    let productID: UInt32?
    let transport: String?
    let source: Source
}

struct PointingDevice: Identifiable, Equatable {
    let id: DeviceIdentifier
    let productName: String?
    let manufacturer: String?
    let vendorID: UInt32?
    let productID: UInt32?
    let transport: String?
    let serialNumber: String?
    let uniqueID: String?
    let locationID: UInt32?
    let primaryUsagePage: UInt32?
    let primaryUsage: UInt32?

    // Preserve the existing exclusion exactly, including missing product names.
    var isExternalMouse: Bool {
        productName != "Apple Internal Keyboard / Trackpad"
    }

    var identityHint: DeviceIdentityHint? {
        let source: DeviceIdentityHint.Source
        if let serialNumber, !serialNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            source = .serialNumber(serialNumber)
        } else if let uniqueID, !uniqueID.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            source = .uniqueID(uniqueID)
        } else if vendorID != nil, productID != nil,
                  let transport, !transport.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let manufacturer, !manufacturer.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
                  let productName, !productName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
            source = .fingerprint(manufacturer: manufacturer, productName: productName)
        } else if let locationID, locationID != 0 {
            source = .location(locationID)
        } else {
            return nil
        }
        return DeviceIdentityHint(
            vendorID: vendorID,
            productID: productID,
            transport: transport,
            source: source
        )
    }
}

/// Keeps every matched HID device, even when reconnect hints collide.
struct PointingDeviceCollection {
    private(set) var devices: [DeviceIdentifier: PointingDevice] = [:]

    var mouseConnected: Bool {
        devices.values.contains { $0.isExternalMouse }
    }

    mutating func add(_ device: PointingDevice) {
        devices[device.id] = device
    }

    mutating func remove(_ identifier: DeviceIdentifier) {
        devices.removeValue(forKey: identifier)
    }

    mutating func removeAll() {
        devices.removeAll()
    }
}
