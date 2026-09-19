import SwiftUI

struct DevicesView: View {
    @ObservedObject var store: DevicePolicyStore
    @State private var showInternalDevices = false

    private var visibleDevices: [DeviceRow] {
        store.rows.filter { showInternalDevices || $0.details.isExternalMouse }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(L10n.devicesTitle).font(.title2.bold())
            Text(L10n.devicesPriorityExplanation)
                .foregroundStyle(.secondary)
            Text(L10n.devicesDisconnectExplanation)
                .font(.caption).foregroundStyle(.secondary)
            Toggle(L10n.devicesShowInternal, isOn: $showInternalDevices)

            if let error = store.storageError {
                Text(error).foregroundStyle(.red)
            }

            if visibleDevices.isEmpty {
                Spacer()
                Text(L10n.devicesEmpty)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(visibleDevices) { device in
                            deviceRow(device)
                        }
                    }
                }
            }
        }
        .padding(24)
        .frame(minWidth: 600, minHeight: 360)
    }

    private func deviceRow(_ device: DeviceRow) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.details.productName ?? L10n.devicesUnknownDevice).font(.headline)
                    Text(verbatim: "\(device.details.manufacturer ?? L10n.devicesUnknownManufacturer) · \(device.details.transport ?? L10n.devicesUnknownTransport)")
                        .foregroundStyle(.secondary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 8) {
                    Picker(L10n.devicesMode, selection: Binding(
                        get: { device.policy.mode },
                        set: { store.setPolicy(DevicePolicy(mode: $0, manualDirection: device.policy.manualDirection), for: device) }
                    )) {
                        ForEach(DeviceMode.allCases) { mode in
                            Text(mode.title).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .accessibilityLabel(L10n.devicesModeAccessibility(device.details.productName ?? L10n.devicesUnknownDevice))
                    Picker(L10n.devicesManualDirection, selection: Binding(
                        get: { device.policy.manualDirection },
                        set: { store.setPolicy(DevicePolicy(mode: .manual, manualDirection: $0), for: device) }
                    )) {
                        ForEach(ManualDirection.allCases) { direction in
                            Text(direction.title).tag(direction)
                        }
                    }
                    .disabled(device.policy.mode == .auto)
                    .accessibilityLabel(L10n.devicesDirectionAccessibility(device.details.productName ?? L10n.devicesUnknownDevice))
                }
                .disabled(device.ambiguous || store.storageError != nil)
                .frame(width: 245)
            }
            Text(L10n.devicesVendorProduct(hex(device.details.vendorID), hex(device.details.productID)))
                .font(.caption.monospaced())
                .foregroundStyle(.secondary)
            if !device.details.isExternalMouse {
                Text(L10n.devicesInternal)
                    .font(.caption).foregroundStyle(.secondary)
            }
            HStack {
                Label(device.connected ? L10n.devicesStatusConnected : L10n.devicesStatusDisconnected,
                      systemImage: device.connected ? "circle.fill" : "circle")
                    .font(.caption)
                    .foregroundStyle(device.connected ? .green : .secondary)
                Spacer()
                if case .known(let id) = device.id, !device.connected {
                    Button(L10n.devicesForget, role: .destructive) { store.forgetDevice(id) }
                        .disabled(store.storageError != nil)
                }
            }
            Text(identityDescription(device))
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .padding(14)
        .background(.quaternary.opacity(0.4), in: RoundedRectangle(cornerRadius: 10))
    }

    private func identityDescription(_ device: DeviceRow) -> String {
        if device.ambiguous {
            return L10n.devicesIdentityAmbiguous
        }
        switch device.confidence {
        case .high:
            return L10n.devicesIdentityHighConfidence
        case .medium:
            return L10n.devicesIdentityMediumConfidence
        case .sessionOnly:
            return L10n.devicesIdentitySessionOnly
        }
    }

    private func hex(_ value: UInt32?) -> String {
        value.map { String(format: "0x%04X", $0) } ?? L10n.devicesUnknownID
    }
}
