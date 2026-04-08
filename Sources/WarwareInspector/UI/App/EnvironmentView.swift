import SwiftUI
import UIKit

/// Shows device and app information useful for bug reports.
struct EnvironmentView: View {

    var body: some View {
        List {
            Section {
                DetailRowView(label: "App Name", value: appName)
                DetailRowView(label: "Version", value: appVersion)
                DetailRowView(label: "Build", value: buildNumber)
                DetailRowView(label: "Bundle ID", value: bundleID)
            } header: {
                Text("App")
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            Section {
                DetailRowView(label: "Device", value: deviceModel)
                DetailRowView(label: "OS", value: osVersion)
                DetailRowView(label: "Screen", value: screenSize)
                DetailRowView(label: "Scale", value: screenScale)
                DetailRowView(label: "Locale", value: locale)
                DetailRowView(label: "Timezone", value: timezone)
                DetailRowView(label: "Preferred Languages", value: preferredLanguages)
            } header: {
                Text("Device")
            }
            .listRowBackground(InspectorTheme.Colors.surface)

            Section {
                DetailRowView(label: "Memory Used", value: memoryUsage)
                DetailRowView(label: "Disk Free", value: diskFree)
                DetailRowView(label: "Battery", value: batteryInfo)
                DetailRowView(label: "Thermal State", value: thermalState)
            } header: {
                Text("System")
            }
            .listRowBackground(InspectorTheme.Colors.surface)
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .inspectorBackground()
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    copyAll()
                } label: {
                    Image(systemName: "doc.on.doc")
                        .font(InspectorTheme.Typography.body)
                        .foregroundStyle(InspectorTheme.Colors.textSecondary)
                }
            }
        }
    }

    // MARK: - App Info

    private var appName: String {
        Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String
            ?? Bundle.main.infoDictionary?["CFBundleName"] as? String
            ?? "Unknown"
    }

    private var appVersion: String {
        Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "Unknown"
    }

    private var buildNumber: String {
        Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "Unknown"
    }

    private var bundleID: String {
        Bundle.main.bundleIdentifier ?? "Unknown"
    }

    // MARK: - Device Info

    private var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machine = withUnsafePointer(to: &systemInfo.machine) {
            $0.withMemoryRebound(to: CChar.self, capacity: 1) {
                String(validatingCString: $0) ?? "Unknown"
            }
        }
        return "\(UIDevice.current.name) (\(machine))"
    }

    private var osVersion: String {
        "\(UIDevice.current.systemName) \(UIDevice.current.systemVersion)"
    }

    private var screenSize: String {
        let bounds = UIScreen.main.bounds
        return "\(Int(bounds.width)) x \(Int(bounds.height)) pt"
    }

    private var screenScale: String {
        "\(Int(UIScreen.main.scale))x"
    }

    private var locale: String {
        Locale.current.identifier
    }

    private var timezone: String {
        TimeZone.current.identifier
    }

    private var preferredLanguages: String {
        Locale.preferredLanguages.prefix(3).joined(separator: ", ")
    }

    // MARK: - System Info

    private var memoryUsage: String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        if result == KERN_SUCCESS {
            return ByteCountFormatter.string(fromByteCount: Int64(info.resident_size), countStyle: .memory)
        }
        return "Unknown"
    }

    private var diskFree: String {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attrs[.systemFreeSize] as? Int64 {
            return ByteCountFormatter.string(fromByteCount: freeSize, countStyle: .file)
        }
        return "Unknown"
    }

    private var batteryInfo: String {
        UIDevice.current.isBatteryMonitoringEnabled = true
        let level = UIDevice.current.batteryLevel
        let state = UIDevice.current.batteryState
        let stateStr: String = switch state {
        case .charging: "Charging"
        case .full: "Full"
        case .unplugged: "Unplugged"
        default: "Unknown"
        }
        if level < 0 { return stateStr }
        return "\(Int(level * 100))% (\(stateStr))"
    }

    private var thermalState: String {
        switch ProcessInfo.processInfo.thermalState {
        case .nominal: "Nominal"
        case .fair: "Fair"
        case .serious: "Serious"
        case .critical: "Critical"
        @unknown default: "Unknown"
        }
    }

    // MARK: - Copy

    private func copyAll() {
        let lines = [
            "App: \(appName) v\(appVersion) (\(buildNumber))",
            "Bundle: \(bundleID)",
            "Device: \(deviceModel)",
            "OS: \(osVersion)",
            "Screen: \(screenSize) @\(screenScale)",
            "Locale: \(locale)",
            "Timezone: \(timezone)",
            "Languages: \(preferredLanguages)",
            "Memory: \(memoryUsage)",
            "Disk Free: \(diskFree)",
            "Battery: \(batteryInfo)",
            "Thermal: \(thermalState)"
        ]
        UIPasteboard.general.string = lines.joined(separator: "\n")
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Environment") {
    NavigationStack {
        EnvironmentView()
            .navigationTitle("Environment")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
