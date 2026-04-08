import SwiftUI
import Darwin

/// Live performance monitor showing memory, CPU, disk, and thermal state.
struct PerformanceView: View {

    @State private var memoryMB: Double = 0
    @State private var cpuPercent: Double = 0
    @State private var diskFreeMB: Double = 0
    @State private var thermalState: String = "Nominal"
    @State private var thermalColor: Color = InspectorTheme.Colors.success

    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: InspectorTheme.Spacing.lg) {
                // Top cards
                HStack(spacing: InspectorTheme.Spacing.md) {
                    metricCard(
                        title: "Memory",
                        value: String(format: "%.1f", memoryMB),
                        unit: "MB",
                        color: memoryColor
                    )
                    metricCard(
                        title: "CPU",
                        value: String(format: "%.0f", cpuPercent),
                        unit: "%",
                        color: cpuColor
                    )
                    metricCard(
                        title: "Thermal",
                        value: thermalState,
                        unit: nil,
                        color: thermalColor
                    )
                }

                // Detail rows
                VStack(spacing: 0) {
                    detailRow(icon: "memorychip", label: "Memory Used", value: String(format: "%.1f MB", memoryMB))
                    rowDivider
                    detailRow(icon: "cpu", label: "CPU Usage", value: String(format: "%.1f%%", cpuPercent))
                    rowDivider
                    detailRow(icon: "internaldrive", label: "Disk Free", value: formatBytes(diskFreeMB))
                    rowDivider
                    detailRow(icon: "thermometer.medium", label: "Thermal State", value: thermalState)
                }
                .background(InspectorTheme.Colors.surface)
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.top, InspectorTheme.Spacing.md)
        }
        .inspectorBackground()
        .onAppear { refreshMetrics() }
        .onReceive(timer) { _ in refreshMetrics() }
    }

    // MARK: - Components

    private func metricCard(title: String, value: String, unit: String?, color: Color) -> some View {
        VStack(spacing: InspectorTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)

            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text(value)
                    .font(.system(size: 22, weight: .bold, design: .monospaced))
                    .foregroundStyle(color)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)

                if let unit {
                    Text(unit)
                        .font(.system(size: 10, weight: .medium))
                        .foregroundStyle(InspectorTheme.Colors.textTertiary)
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, InspectorTheme.Spacing.lg)
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    private func detailRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: InspectorTheme.Spacing.md) {
            Image(systemName: icon)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.accent)
                .frame(width: 28, height: 28)
                .background(InspectorTheme.Colors.accent.opacity(0.12))
                .clipShape(.rect(cornerRadius: InspectorTheme.Radius.sm))

            Text(label)
                .font(InspectorTheme.Typography.body)
                .fontWeight(.medium)
                .foregroundStyle(InspectorTheme.Colors.textPrimary)

            Spacer()

            Text(value)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.md)
    }

    private var rowDivider: some View {
        Divider()
            .overlay(InspectorTheme.Colors.border)
            .padding(.leading, 58)
    }

    // MARK: - Colors

    private var memoryColor: Color {
        if memoryMB > 200 { return InspectorTheme.Colors.error }
        if memoryMB > 100 { return InspectorTheme.Colors.warning }
        return InspectorTheme.Colors.success
    }

    private var cpuColor: Color {
        if cpuPercent > 80 { return InspectorTheme.Colors.error }
        if cpuPercent > 40 { return InspectorTheme.Colors.warning }
        return InspectorTheme.Colors.success
    }

    // MARK: - Data Collection

    private func refreshMetrics() {
        memoryMB = memoryUsageMB()
        cpuPercent = cpuUsage()
        diskFreeMB = diskFreeBytes()
        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal:
            thermalState = "Nominal"
            thermalColor = InspectorTheme.Colors.success
        case .fair:
            thermalState = "Fair"
            thermalColor = InspectorTheme.Colors.pending
        case .serious:
            thermalState = "Serious"
            thermalColor = InspectorTheme.Colors.warning
        case .critical:
            thermalState = "Critical"
            thermalColor = InspectorTheme.Colors.error
        @unknown default:
            thermalState = "Unknown"
            thermalColor = InspectorTheme.Colors.textTertiary
        }
    }

    private func memoryUsageMB() -> Double {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let result = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return result == KERN_SUCCESS ? Double(info.resident_size) / 1_048_576 : 0
    }

    private func cpuUsage() -> Double {
        var totalUsageOfCPU: Double = 0.0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let threadsResult = task_threads(mach_task_self_, &threadsList, &threadsCount)

        if threadsResult == KERN_SUCCESS, let threadsList = threadsList {
            for index in 0..<threadsCount {
                var threadInfo = thread_basic_info()
                var threadInfoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
                let infoResult = withUnsafeMutablePointer(to: &threadInfo) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(index)], thread_flavor_t(THREAD_BASIC_INFO), $0, &threadInfoCount)
                    }
                }
                if infoResult == KERN_SUCCESS {
                    let usage = threadInfo.cpu_usage
                    totalUsageOfCPU += Double(usage) / Double(TH_USAGE_SCALE) * 100.0
                }
            }
            vm_deallocate(
                mach_task_self_,
                vm_address_t(bitPattern: threadsList),
                vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride)
            )
        }
        return totalUsageOfCPU
    }

    private func diskFreeBytes() -> Double {
        if let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()),
           let freeSize = attrs[.systemFreeSize] as? Int64 {
            return Double(freeSize)
        }
        return 0
    }

    private func formatBytes(_ bytes: Double) -> String {
        let formatter = ByteCountFormatter()
        formatter.countStyle = .file
        return formatter.string(fromByteCount: Int64(bytes))
    }
}

// MARK: - Previews

#if DEBUG
#Preview("Performance") {
    NavigationStack {
        PerformanceView()
            .navigationTitle("Performance")
            .navigationBarTitleDisplayMode(.inline)
    }
}
#endif
