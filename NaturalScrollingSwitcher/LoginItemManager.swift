//
//  LoginItemManager.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Foundation
import Combine
import ServiceManagement

final class LoginItemManager: ObservableObject {

    @Published private(set) var isEnabled = false

    init() {
        updateStatus()
    }

    func updateStatus() {
        isEnabled = SMAppService.mainApp.status == .enabled
    }

    func setEnabled(_ enabled: Bool) {

        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }

            updateStatus()

            print("Launch at login → \(enabled ? "ON" : "OFF")")

        } catch {
            print("Failed to change launch at login:")
            print(error)
        }
    }
}
