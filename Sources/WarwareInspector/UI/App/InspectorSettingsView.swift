import SwiftUI

/// Settings for the inspector: host blacklist, network simulation, etc.
struct InspectorSettingsView: View {
    @Bindable var store: InspectorStore

    @State private var newBlacklistHost = ""

    var body: some View {
        List {
            // Host Blacklist
            Section {
                ForEach(Array(store.blacklistedHosts.sorted()), id: \.self) { host in
                    HStack {
                        Text(host)
                            .font(InspectorTheme.Typography.code)
                            .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        Spacer()
                        Button {
                            store.blacklistedHosts.remove(host)
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        }
                    }
                }

                HStack {
                    TextField("analytics.example.com", text: $newBlacklistHost)
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                        .autocorrectionDisabled()
                        .textInputAutocapitalization(.never)

                    Button {
                        let host = newBlacklistHost.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !host.isEmpty else { return }
                        store.blacklistedHosts.insert(host)
                        newBlacklistHost = ""
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .foregroundStyle(InspectorTheme.Colors.accent)
                    }
                    .disabled(newBlacklistHost.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            } header: {
                Text("Host Blacklist")
            } footer: {
                Text("Requests to these hosts won't be captured by the inspector.")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Data
            Section {
                HStack {
                    Text("Max Network Entries")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    Spacer()
                    Text("200")
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

                HStack {
                    Text("Max Console Entries")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textPrimary)
                    Spacer()
                    Text("500")
                        .font(InspectorTheme.Typography.code)
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }

                Button(role: .destructive) {
                    store.clearAll()
                } label: {
                    HStack {
                        Image(systemName: "trash")
                        Text("Clear All Data")
                    }
                    .foregroundStyle(InspectorTheme.Colors.error)
                }
            } header: {
                Text("Data")
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Network Throttle
            Section {
                ForEach(NetworkThrottle.allCases, id: \.self) { preset in
                    Button {
                        store.networkThrottle = preset
                    } label: {
                        HStack {
                            VStack(alignment: .leading, spacing: InspectorTheme.Spacing.xxs) {
                                Text(preset.rawValue)
                                    .font(InspectorTheme.Typography.body)
                                    .foregroundStyle(InspectorTheme.Colors.textPrimary)
                                Text(preset.description)
                                    .font(InspectorTheme.Typography.detail)
                                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
                            }
                            Spacer()
                            if store.networkThrottle == preset {
                                Image(systemName: "checkmark")
                                    .font(InspectorTheme.Typography.detail)
                                    .fontWeight(.semibold)
                                    .foregroundStyle(InspectorTheme.Colors.accent)
                            }
                        }
                    }
                }
            } header: {
                Text("Network Conditions")
            } footer: {
                Text("Simulates network latency and failures on real devices.")
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            // Coming Soon
            Section {
                comingSoonRow(icon: "location", title: "Mock Location", color: InspectorTheme.Colors.success)
                comingSoonRow(icon: "flag", title: "Feature Flags", color: InspectorTheme.Colors.accent)
            } header: {
                Text("Coming Soon")
            }
            .listRowBackground(InspectorTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .inspectorBackground()
    }

    private func comingSoonRow(icon: String, title: String, color: Color) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: icon)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(color.opacity(0.5))

            Text(title)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            Spacer()

            Text("Soon")
                .font(InspectorTheme.Typography.detail)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
        }
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Settings") {
    NavigationStack {
        InspectorSettingsView(store: .preview)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview("Settings - With Blacklist") {
    NavigationStack {
        InspectorSettingsView(store: {
            let s = InspectorStore()
            s.blacklistedHosts = ["analytics.example.com", "crashlytics.com"]
            return s
        }())
        .navigationTitle("Settings")
        .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
