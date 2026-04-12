import SwiftUI

/// Settings for the inspector: appearance, capture, data, about.
@_spi(PryPro) public struct PrySettingsView: View {
    @Bindable @_spi(PryPro) public var store: PryStore

    @State private var newBlacklistHost = ""
    @State private var showClearConfirmation = false
    @State private var clearAction: ClearAction?

    private enum ClearAction: Identifiable {
        case network, console, deeplinks, push, all
        var id: String { "\(self)" }
    }

    @_spi(PryPro) public init(store: PryStore) {
        self.store = store
    }

    @_spi(PryPro) public var body: some View {
        List {
            appearanceSection
            captureSection
            dataSection
            aboutSection
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .pryBackground()
        .alert("Clear Data?", isPresented: $showClearConfirmation) {
            Button("Clear", role: .destructive) {
                switch clearAction {
                case .network: store.clearNetwork()
                case .console: store.clearLogs()
                case .deeplinks: store.clearDeeplinks()
                case .push: store.clearPush()
                case .all: store.clearAll()
                case nil: break
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            switch clearAction {
            case .network: Text("This will remove all captured network requests.")
            case .console: Text("This will remove all console logs.")
            case .deeplinks: Text("This will remove all captured deeplinks.")
            case .push: Text("This will remove all captured push notifications.")
            case .all: Text("This will remove all captured data.")
            case nil: Text("")
            }
        }
    }

    // MARK: - Appearance

    private var appearanceSection: some View {
        Section {
            // Trigger
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                Text("Open with")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                Picker("", selection: triggerBinding) {
                    Text("Button").tag(0)
                    Text("Shake").tag(1)
                    Text("Both").tag(2)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, PryTheme.Spacing.xs)

            // FAB position
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                Text("Button position")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                Picker("", selection: $store.fabOnLeft) {
                    Text("Left").tag(true)
                    Text("Right").tag(false)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, PryTheme.Spacing.xs)

            // Draggable
            Toggle(isOn: $store.fabDraggable) {
                settingRow(title: "Draggable button", subtitle: "Drag the FAB to reposition it")
            }
            .tint(PryTheme.Colors.accent)

            // Error badge
            Toggle(isOn: $store.showErrorBadge) {
                settingRow(title: "Error badge", subtitle: "Show error count on the button")
            }
            .tint(PryTheme.Colors.accent)

            // Auth
            Toggle(isOn: $store.requireAuth) {
                settingRow(title: "Require authentication", subtitle: "FaceID, TouchID, or passcode to open")
            }
            .tint(PryTheme.Colors.accent)

            // Theme
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                Text("Theme")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textPrimary)

                Picker("", selection: $store.themeOverride) {
                    Text("System").tag(0)
                    Text("Light").tag(1)
                    Text("Dark").tag(2)
                }
                .pickerStyle(.segmented)
            }
            .padding(.vertical, PryTheme.Spacing.xs)
        } header: {
            Text("Appearance")
        }
        .listRowBackground(PryTheme.Colors.surface)
    }

    // MARK: - Capture

    private var captureSection: some View {
        Section {
            Toggle(isOn: $store.printToConsole) {
                settingRow(title: "Mirror to Xcode", subtitle: "Print logs to the Xcode console")
            }
            .tint(PryTheme.Colors.accent)

            // Blacklist
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                settingRow(title: "Host blacklist", subtitle: "Requests to these hosts won't be captured")

                if !store.blacklistedHosts.isEmpty {
                    VStack(spacing: 0) {
                        ForEach(Array(store.blacklistedHosts.sorted()), id: \.self) { host in
                            HStack {
                                Text(host)
                                    .font(PryTheme.Typography.code)
                                    .foregroundStyle(PryTheme.Colors.textPrimary)
                                Spacer()
                                Button {
                                    store.blacklistedHosts.remove(host)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(PryTheme.Colors.error)
                                }
                            }
                            .padding(.vertical, PryTheme.Spacing.xs)
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
            }
            .padding(.vertical, PryTheme.Spacing.xs)
        } header: {
            Text("Capture")
        }
        .listRowBackground(PryTheme.Colors.surface)
    }

    // MARK: - Data

    private var dataSection: some View {
        Section {
            // Usage info
            VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
                settingRow(title: "Captured data", subtitle: dataSummary)
            }
            .padding(.vertical, PryTheme.Spacing.xs)

            // Clear per type
            if store.networkEntries.count > 0 {
                clearButton("Clear Network", count: store.networkEntries.count, action: .network)
            }
            if store.logEntries.count > 0 {
                clearButton("Clear Console", count: store.logEntries.count, action: .console)
            }
            if store.deeplinkEntries.count > 0 {
                clearButton("Clear Deeplinks", count: store.deeplinkEntries.count, action: .deeplinks)
            }
            if store.pushNotificationEntries.count > 0 {
                clearButton("Clear Push", count: store.pushNotificationEntries.count, action: .push)
            }

            Button {
                clearAction = .all
                showClearConfirmation = true
            } label: {
                Text("Clear All Data")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.error)
            }
        } header: {
            Text("Data")
        }
        .listRowBackground(PryTheme.Colors.surface)
    }

    // MARK: - About

    private var aboutSection: some View {
        Section {
            HStack {
                Text("Version")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                Spacer()
                Text(versionLabel)
                    .font(PryTheme.Typography.code)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            HStack {
                Text("Author")
                    .font(PryTheme.Typography.body)
                    .foregroundStyle(PryTheme.Colors.textPrimary)
                Spacer()
                Text("Alvaro Guerra Freitas")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
        } header: {
            Text("About")
        }
        .listRowBackground(PryTheme.Colors.surface)
    }

    // MARK: - Helpers

    private func clearButton(_ title: String, count: Int, action: ClearAction) -> some View {
        Button {
            clearAction = action
            showClearConfirmation = true
        } label: {
            HStack {
                Text(title)
                    .font(PryTheme.Typography.body)
                Spacer()
                Text("\(count)")
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }
            .foregroundStyle(PryTheme.Colors.error)
        }
    }

    private func settingRow(title: String, subtitle: String) -> some View {
        VStack(alignment: .leading, spacing: PryTheme.Spacing.xxs) {
            Text(title)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textPrimary)
            Text(subtitle)
                .font(PryTheme.Typography.detail)
                .foregroundStyle(PryTheme.Colors.textTertiary)
        }
    }

    private var dataSummary: String {
        let parts = [
            "\(store.networkEntries.count) requests",
            "\(store.logEntries.count) logs",
            "\(store.deeplinkEntries.count) deeplinks",
            "\(store.pushNotificationEntries.count) push"
        ]
        return parts.joined(separator: " \u{00B7} ")
    }

    @_spi(PryPro) public static let version = "1.2.1"

    private var versionLabel: String {
        "Pry \(Self.version)"
    }

    private var triggerBinding: Binding<Int> {
        Binding(
            get: {
                let t = store.triggerOverride ?? .default
                if t.contains(.floatingButton) && t.contains(.shake) { return 2 }
                if t.contains(.shake) { return 1 }
                return 0
            },
            set: { value in
                switch value {
                case 1: store.triggerOverride = .shake
                case 2: store.triggerOverride = [.floatingButton, .shake]
                default: store.triggerOverride = .floatingButton
                }
            }
        )
    }
}

#if DEBUG
#Preview("Settings") {
    NavigationStack {
        PrySettingsView(store: .preview)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
