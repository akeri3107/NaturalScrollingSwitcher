//
//  MouseDetector.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Foundation
import IOKit.hid

final class MouseDetector {

    private let manager: IOHIDManager

    init() {
        manager = IOHIDManagerCreate(
            kCFAllocatorDefault,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )

        IOHIDManagerSetDeviceMatching(
            manager,
            [
                kIOHIDDeviceUsagePageKey: kHIDPage_GenericDesktop,
                kIOHIDDeviceUsageKey: kHIDUsage_GD_Mouse
            ] as CFDictionary
        )

        IOHIDManagerScheduleWithRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )

        IOHIDManagerOpen(
            manager,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )
    }

    deinit {
        IOHIDManagerUnscheduleFromRunLoop(
            manager,
            CFRunLoopGetMain(),
            CFRunLoopMode.defaultMode.rawValue
        )

        IOHIDManagerClose(
            manager,
            IOOptionBits(kIOHIDOptionsTypeNone)
        )
    }

    func isMouseConnected() -> Bool {
        guard let devices = IOHIDManagerCopyDevices(manager) else {
            return false
        }

        let count = CFSetGetCount(devices)

        if count == 0 {
            return false
        }

        var values = [UnsafeRawPointer?](
            repeating: nil,
            count: count
        )

        CFSetGetValues(
            devices,
            &values
        )

        for value in values {
            guard let value = value else {
                continue
            }

            let device = Unmanaged<IOHIDDevice>
                .fromOpaque(value)
                .takeUnretainedValue()

            if isExternalMouse(device) {
                return true
            }
        }

        return false
    }

    private func isExternalMouse(_ device: IOHIDDevice) -> Bool {
        let product = IOHIDDeviceGetProperty(
            device,
            kIOHIDProductKey as CFString
        ) as? String ?? "Unknown Device"

        let manufacturer = IOHIDDeviceGetProperty(
            device,
            kIOHIDManufacturerKey as CFString
        ) as? String ?? "Unknown Manufacturer"

        let transport = IOHIDDeviceGetProperty(
            device,
            kIOHIDTransportKey as CFString
        ) as? String ?? "Unknown Transport"

        print("🖱️ Mouse candidate")
        print("   Product: \(product)")
        print("   Manufacturer: \(manufacturer)")
        print("   Transport: \(transport)")

        // MacBook 내장 키보드/트랙패드 제외
        if product == "Apple Internal Keyboard / Trackpad" {
            print("   → Ignored (Apple internal device)")
            return false
        }

        print("   → External mouse detected")
        return true
    }
}
