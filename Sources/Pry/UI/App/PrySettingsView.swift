import SwiftUI

/// Settings for the inspector: presentation, behavior, blacklist, data.
@_spi(PryPro) public struct PrySettingsView: View {
    @Bindable @_spi(PryPro) public var store: PryStore

    @State private var newBlacklistHost = ""

    @_spi(PryPro) public init(store: PryStore) {
        self.store = store
    }

    @_spi(PryPro) public var body: some View {
        List {
            // Presentation
            Section {
                // Trigger mode
                HStack {
                    Text("Open with")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                    Spacer()
                    Menu {
                        Button {
                            store.triggerOverride = .floatingButton
                        } label: {
                            Label("Floating Button", systemImage: "circle.fill")
                            if triggerLabel == "Button" { Image(systemName: "checkmark") }
                        }
                        Button {
                            store.triggerOverride = .shake
                        } label: {
                            Label("Shake", systemImage: "iphone.radiowaves.left.and.right")
                            if triggerLabel == "Shake" { Image(systemName: "checkmark") }
                        }
                        Button {
                            store.triggerOverride = [.floatingButton, .shake]
                        } label: {
                            Label("Both", systemImage: "square.stack")
                            if triggerLabel == "Both" { Image(systemName: "checkmark") }
                        }
                    } label: {
                        HStack(spacing: PryTheme.Spacing.xs) {
                            Text(triggerLabel)
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.accent)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(PryTheme.Typography.smallIcon)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                        }
                    }
                }

                // FAB position
                HStack {
                    Text("Button position")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                    Spacer()
                    Menu {
                        Button {
                            store.fabOnLeft = false
                        } label: {
                            Label("Right", systemImage: "rectangle.righthalf.filled")
                            if !store.fabOnLeft { Image(systemName: "checkmark") }
                        }
                        Button {
                            store.fabOnLeft = true
                        } label: {
                            Label("Left", systemImage: "rectangle.lefthalf.filled")
                            if store.fabOnLeft { Image(systemName: "checkmark") }
                        }
                    } label: {
                        HStack(spacing: PryTheme.Spacing.xs) {
                            Text(store.fabOnLeft ? "Left" : "Right")
                                .font(PryTheme.Typography.code)
                                .foregroundStyle(PryTheme.Colors.accent)
                            Image(systemName: "chevron.up.chevron.down")
                                .font(PryTheme.Typography.smallIcon)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                        }
                    }
                }

                // Draggable
                Toggle(isOn: $store.fabDraggable) {
                    Text("Draggable button")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                }
                .tint(PryTheme.Colors.accent)

                // Error badge
                Toggle(isOn: $store.showErrorBadge) {
                    Text("Error badge on button")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                }
                .tint(PryTheme.Colors.accent)
            } header: {
                Text("Presentation")
            }
            .listRowBackground(PryTheme.Colors.surface)

            // Behavior
            Section {
                Toggle(isOn: $store.printToConsole) {
                    Text("Print logs to Xcode console")
                        .font(PryTheme.Typography.body)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                }
                .tint(PryTheme.Colors.accent)
            } header: {
                Text("Behavior")
            }
            .listRowBackground(PryTheme.Colors.surface)

            // Host Blacklist
            Section {
                ForEach(Array(store.blacklistedHosts.sorted()), id: \.self) { host in
                    HStack {
                        Text(host)
                            .font(PryTheme.Typography.code)
                            .foregroundStyle(PryTheme.Colors.textPrimary)
                        Spacer()
                        Button {
                            store.blacklistedHosts.remove(host)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                        }
                    }
                }

                HStack {
                    TextField("analytics.example.com", text: $newBlacklistHost)
                        .font(PryTheme.Typography.code)
                        .foregroundStyle(PryTheme.Colors.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        let host = newBlacklistHost.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !host.isEmpty else { return }
                        store.blacklistedHosts.insert(host)
                        newBlacklistHost = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(PryTheme.Colors.accent)
                    }
                    .disabled(newBlacklistHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Host Blacklist")
            } footer: {
                Text("Requests to these hosts won't be captured.")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
            .listRowBackground(PryTheme.Colors.surface)

            // Data
            Section {
                Button(role: .destructive) {
                    store.clearAll()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Data")
                    }
                    .foregroundStyle(PryTheme.Colors.error)
                }
            } header: {
                Text("Data")
            }
            .listRowBackground(PryTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .pryBackground()
    }

    // MARK: - Helpers

    private var activeTrigger: PryTrigger {
        store.triggerOverride ?? .default
    }

    private var triggerLabel: String {
        if activeTrigger.contains(.floatingButton) && activeTrigger.contains(.shake) { return "Both" }
        if activeTrigger.contains(.shake) { return "Shake" }
        return "Button"
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Settings") {
    NavigationStack {
        PrySettingsView(store: .preview)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Settings - With Blacklist") {
    NavigationStack {
        PrySettingsView(store: {
            let s = PryStore()
            s.blacklistedHosts = ["analytics.example.com", "crashlytics.com"]
            return s
        }())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
