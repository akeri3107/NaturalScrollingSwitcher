import Foundation

enum DeviceIdentityConfidence: String, Codable {
    case high, medium, sessionOnly
}

extension DeviceIdentityHint {
    var confidence: DeviceIdentityConfidence {
        guard vendorID != nil, productID != nil,
              let transport, !transport.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return .sessionOnly
        }
        switch source {
        case .serialNumber, .uniqueID: return .high
        case .fingerprint: return .medium
        case .location: return .sessionOnly
        }
    }
}

/// Only descriptive HID properties are persisted; no registry or location IDs.
struct DeviceDetails: Codable, Equatable {
    let productName: String?
    let manufacturer: String?
    let transport: String?
    let vendorID: UInt32?
    let productID: UInt32?
    let usagePage: UInt32?
    let usage: UInt32?

    init(_ device: PointingDevice) {
        productName = device.productName
        manufacturer = device.manufacturer
        transport = device.transport
        vendorID = device.vendorID
        productID = device.productID
        usagePage = device.primaryUsagePage
        usage = device.primaryUsage
    }

    init(productName: String?, manufacturer: String?, transport: String?, vendorID: UInt32?,
         productID: UInt32?, usagePage: UInt32?, usage: UInt32?) {
        self.productName = productName
        self.manufacturer = manufacturer
        self.transport = transport
        self.vendorID = vendorID
        self.productID = productID
        self.usagePage = usagePage
        self.usage = usage
    }

    var isExternalMouse: Bool { productName != "Apple Internal Keyboard / Trackpad" }
}

struct KnownDevice: Identifiable, Codable, Equatable {
    let id: UUID
    let identity: DeviceIdentityHint?
    let details: DeviceDetails
    var policy: DevicePolicy

    var confidence: DeviceIdentityConfidence { identity?.confidence ?? .sessionOnly }
}

struct DeviceRow: Identifiable {
    enum ID: Hashable {
        case known(UUID)
        case connected(DeviceIdentifier)
    }
    let id: ID
    let details: DeviceDetails
    let policy: DevicePolicy
    let connected: Bool
    let ambiguous: Bool
    let confidence: DeviceIdentityConfidence
}
