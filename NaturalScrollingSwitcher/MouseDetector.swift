//
//  MouseDetector.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Foundation
import Combine
import IOKit
import IOKit.hid

@MainActor
final class MouseDetector: ObservableObject {

    private var manager: IOHIDManager?
    private var deviceCollection = PointingDeviceCollection()
    // Retain the callback's device and its assigned ID until removal. This also
    // preserves UUID fallbacks and avoids querying properties after termination.
    private var identifiersByDevice: [IOHIDDevice: DeviceIdentifier] = [:]

    @Published private(set) var connectedDevices: [DeviceIdentifier: PointingDevice] = [:]
    private var onStateChange: ((Bool) -> Void)?
    private var lastReportedState: Bool?

    func start(onStateChange: @escaping (Bool) -> Void) {
        guard manager == nil else { return }

        let manager = IOHIDManagerCreate(
            kCFAllocatorDefault,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )
        self.manager = manager
        self.onStateChange = onStateChange

        IOHIDManagerSetDeviceMatching(
            manager,
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse
            ] as CFDictionary
        )

        // The owner retains this detector until callbacks have been unregistered.
        // Both callbacks run on the main run loop, including menu tracking mode.
        let context = Unmanaged.passUnretained(self).toOpaque()
        IOHIDManagerRegisterDeviceMatchingCallback(manager, { context, result, _, device in
            guard let context, result == kIOReturnSuccess else { return }
            MainActor.assumeIsolated {
                let detector = Unmanaged<MouseDetector>.fromOpaque(context).takeUnretainedValue()
                detector.deviceAdded(device)
            }
        }, context)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, { context, _, _, device in
            guard let context else { return }
            MainActor.assumeIsolated {
                let detector = Unmanaged<MouseDetector>.fromOpaque(context).takeUnretainedValue()
                detector.deviceRemoved(device)
            }
        }, context)

        IOHIDManagerScheduleWithRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )

        // Matching/removal notifications and device properties do not require
        // opening HID devices. Keep the manager unopened: opening it also opens
        // current/future mice for input access, which can be denied by TCC.

        // Seed once after registering callbacks so startup needs no plug/unplug.
        // The device map makes subsequent matching callbacks idempotent.
        if let devices = IOHIDManagerCopyDevices(manager) as? Set<IOHIDDevice> {
            for device in devices {
                trackDevice(device)
            }
        }
        reportStateIfChanged()
    }

    func stop() {
        guard let manager else { return }
        onStateChange = nil
        IOHIDManagerRegisterDeviceMatchingCallback(manager, nil, nil)
        IOHIDManagerRegisterDeviceRemovalCallback(manager, nil, nil)
        IOHIDManagerUnscheduleFromRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.commonModes.rawValue
        )
        // No close is needed because this manager is never opened.
        self.manager = nil
        identifiersByDevice.removeAll()
        deviceCollection.removeAll()
        connectedDevices = [:]
        lastReportedState = nil
    }

    isolated deinit {
        stop()
    }

    func isMouseConnected() -> Bool {
        deviceCollection.mouseConnected
    }

    private func deviceAdded(_ device: IOHIDDevice) {
        trackDevice(device)
        reportStateIfChanged()
    }

    private func deviceRemoved(_ device: IOHIDDevice) {
        if let identifier = identifiersByDevice.removeValue(forKey: device) {
            deviceCollection.remove(identifier)
        }
        reportStateIfChanged()
    }

    private func trackDevice(_ device: IOHIDDevice) {
        guard identifiersByDevice[device] == nil else { return }
        var registryID: UInt64 = 0
        let service = IOHIDDeviceGetService(device)
        let identifier: DeviceIdentifier
        if service != 0,
           IORegistryEntryGetRegistryEntryID(service, &registryID) == kIOReturnSuccess {
            identifier = .registryEntry(registryID)
        } else {
            identifier = .session(UUID())
        }
        // IOHIDDeviceGetService returns a borrowed service; do not release it.
        let record = describeDevice(device, identifier: identifier)
        identifiersByDevice[device] = identifier
        deviceCollection.add(record)
    }

    private func reportStateIfChanged() {
        // Publish individual changes even when the aggregate mouse state stays true.
        if connectedDevices != deviceCollection.devices {
            connectedDevices = deviceCollection.devices
        }
        let connected = isMouseConnected()
        guard lastReportedState != connected else { return }
        lastReportedState = connected
        onStateChange?(connected)
    }

    private func describeDevice(
        _ device: IOHIDDevice,
        identifier: DeviceIdentifier
    ) -> PointingDevice {
        func string(_ key: String) -> String? {
            IOHIDDeviceGetProperty(device, key as CFString) as? String
        }
        func number(_ key: String) -> UInt32? {
            (IOHIDDeviceGetProperty(device, key as CFString) as? NSNumber)?.uint32Value
        }

        let record = PointingDevice(
            id: identifier,
            productName: string(kIOHIDProductKey),
            manufacturer: string(kIOHIDManufacturerKey),
            vendorID: number(kIOHIDVendorIDKey),
            productID: number(kIOHIDProductIDKey),
            transport: string(kIOHIDTransportKey),
            serialNumber: string(kIOHIDSerialNumberKey),
            uniqueID: string(kIOHIDUniqueIDKey),
            locationID: number(kIOHIDLocationIDKey),
            primaryUsagePage: number(kIOHIDPrimaryUsagePageKey),
            primaryUsage: number(kIOHIDPrimaryUsageKey)
        )
        print("🖱️ Mouse candidate: \(record.productName ?? "Unknown Device")")
        print("   → \(record.isExternalMouse ? "External mouse detected" : "Ignored (Apple internal device)")")
        return record
    }
}
