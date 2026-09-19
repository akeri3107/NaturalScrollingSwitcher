//
//  ScrollMonitor.swift
//  NaturalScrollingSwitcher
//
//  Created by Akeri on 8/26/26.
//

import Foundation
import Combine

@MainActor
final class ScrollMonitor: ObservableObject {
    private let mouseDetector: MouseDetector
    private let policyStore: DevicePolicyStore
    private let applyScrolling: (Bool) -> Void
    private let defaults: UserDefaults
    private var devicesSubscription: AnyCancellable?
    private var priority = DevicePolicyPriority()
    private var lastAppliedDirection: Bool?
    private var isRunning = false
    private var initialEnumerationCompleted = false
    static let controlEnabledDefaultsKey = "scrollControlEnabled"

    @Published private(set) var mouseConnected = false
    @Published private(set) var naturalScrollingEnabled = true
    @Published private(set) var isControlEnabled: Bool

    func setControlEnabled(_ enabled: Bool) {
        guard isControlEnabled != enabled else { return }
        isControlEnabled = enabled
        defaults.set(enabled, forKey: Self.controlEnabledDefaultsKey)
        // The system preference may be changed elsewhere while control is off.
        // Re-enabling must apply even if the desired value matches our old cache.
        lastAppliedDirection = nil
        if enabled { applyCurrentPolicy() }
    }

    init(
        mouseDetector: MouseDetector? = nil,
        scrollManager: ScrollManager? = nil,
        policyStore: DevicePolicyStore? = nil,
        defaults: UserDefaults = .standard,
        applyScrolling: ((Bool) -> Void)? = nil
    ) {
        let detector = mouseDetector ?? MouseDetector()
        self.mouseDetector = detector
        self.policyStore = policyStore ?? DevicePolicyStore(defaults: defaults)
        self.defaults = defaults
        if let applyScrolling {
            self.applyScrolling = applyScrolling
        } else {
            let manager = scrollManager ?? ScrollManager()
            self.applyScrolling = { manager.setNaturalScrolling($0) }
        }
        if defaults.object(forKey: Self.controlEnabledDefaultsKey) != nil {
            isControlEnabled = defaults.bool(forKey: Self.controlEnabledDefaultsKey)
        } else {
            let legacy = defaults.string(forKey: "naturalScrollingMode")
            // Preserve a formerly forced direction by leaving system control off.
            isControlEnabled = legacy != "on" && legacy != "off"
            defaults.set(isControlEnabled, forKey: Self.controlEnabledDefaultsKey)
        }
        defaults.removeObject(forKey: "naturalScrollingMode")
        self.policyStore.onChange = { [weak self] change in
            self?.policiesChanged(change)
        }
        devicesSubscription = detector.$connectedDevices.sink { [weak self] devices in
            // @Published emits before the detector property is assigned. Use the
            // supplied snapshot, and evaluate only after matching has completed.
            self?.policyStore.updateDevices(devices)
        }
    }

    func start() {
        guard !isRunning else { return }
        isRunning = true
        mouseDetector.start { [weak self] _ in
            guard let self else { return }
            // The first aggregate callback follows the complete initial snapshot,
            // including startup with no matching devices.
            self.initialEnumerationCompleted = true
            self.applyCurrentPolicy()
        }
    }

    func stop() {
        isRunning = false
        initialEnumerationCompleted = false
        mouseDetector.stop()
        priority = DevicePolicyPriority()
        lastAppliedDirection = nil
    }

    private func policiesChanged(_ change: DevicePolicyStore.Change) {
        let devices = policyStore.devices
        priority.updateDevices(devices)
        mouseConnected = devices.contains { $0.isExternalMouse }
        switch change {
        case .devicesUpdated:
            if isRunning { applyCurrentPolicy() }
        case .policyChanged(let id):
            guard isRunning, let id,
                  devices.contains(where: { $0.id == id && $0.isExternalMouse }) else { return }
            priority.policyChanged(for: id)
            // Policy edits never implicitly re-enable global control.
            applyCurrentPolicy()
        }
    }

    private func applyCurrentPolicy() {
        guard isRunning, initialEnumerationCompleted, isControlEnabled else { return }
        let selected = policyStore.devices.first { $0.id == priority.selectedDevice }
        let policy = selected.map { policyStore.policy(for: $0) } ?? DevicePolicy()
        let enabled = policy.mode == .manual ? policy.manualDirection.naturalScrollingEnabled : !mouseConnected
        guard lastAppliedDirection != enabled else { return }
        applyScrolling(enabled)
        naturalScrollingEnabled = enabled
        lastAppliedDirection = enabled
    }
}
