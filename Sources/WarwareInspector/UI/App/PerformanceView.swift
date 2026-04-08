import SwiftUI
import Charts
import UIKit
import Darwin

/// Live performance monitor with charts, memory, CPU, disk, battery, and thread info.
struct PerformanceView: View {

    @State private var memoryMB: Double = 0
    @State private var memoryPeakMB: Double = 0
    @State private var cpuPercent: Double = 0
    @State private var threadCount: Int = 0
    @State private var diskFreeMB: Double = 0
    @State private var diskTotalMB: Double = 0
    @State private var thermalState: String = "Nominal"
    @State private var thermalColor: Color = InspectorTheme.Colors.success
    @State private var batteryLevel: Float = -1
    @State private var batteryState: String = "Unknown"
    @State private var uptimeSeconds: TimeInterval = 0

    // Chart data: last 60 seconds
    @State private var memoryHistory: [ChartPoint] = []
    @State private var cpuHistory: [ChartPoint] = []
    @State private var tickCount: Int = 0

    private let maxHistory = 60
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    var body: some View {
        ScrollView {
            VStack(spacing: InspectorTheme.Spacing.lg) {
                // Memory chart
                chartSection(
                    title: "Memory",
                    value: String(format: "%.0f MB", memoryMB),
                    peak: String(format: "Peak: %.0f MB", memoryPeakMB),
                    color: memoryColor,
                    data: memoryHistory,
                    yLabel: "MB"
                )

                // CPU chart
                chartSection(
                    title: "CPU",
                    value: String(format: "%.0f%%", cpuPercent),
                    peak: "\(threadCount) threads",
                    color: cpuColor,
                    data: cpuHistory,
                    yLabel: "%"
                )

                // Live cards: 2x2
                LazyVGrid(columns: [
                    GridItem(.flexible(), spacing: InspectorTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: InspectorTheme.Spacing.sm)
                ], spacing: InspectorTheme.Spacing.sm) {
                    smallCard(title: "Threads", value: "\(threadCount)", color: InspectorTheme.Colors.accent)
                    smallCard(title: "Thermal", value: thermalState, color: thermalColor)
                    smallCard(title: "Battery", value: batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "N/A", color: batteryLevelColor)
                    smallCard(title: "Uptime", value: formatUptime(uptimeSeconds), color: InspectorTheme.Colors.textSecondary)
                }

                // Detail sections
                sectionCard(title: "Memory") {
                    detailRow(label: "Used", value: String(format: "%.1f MB", memoryMB), color: memoryColor)
                    rowDivider
                    detailRow(label: "Peak (session)", value: String(format: "%.1f MB", memoryPeakMB), color: InspectorTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Device RAM", value: formatBytes(Double(ProcessInfo.processInfo.physicalMemory)), color: InspectorTheme.Colors.textSecondary)
                }

                sectionCard(title: "Storage") {
                    detailRow(label: "Free", value: formatBytes(diskFreeMB), color: InspectorTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Total", value: formatBytes(diskTotalMB), color: InspectorTheme.Colors.textSecondary)
                    if diskTotalMB > 0 {
                        rowDivider
                        let pct = ((diskTotalMB - diskFreeMB) / diskTotalMB) * 100
                        detailRow(label: "Used", value: String(format: "%.0f%%", pct), color: pct > 90 ? InspectorTheme.Colors.error : InspectorTheme.Colors.textSecondary)
                    }
                }

                sectionCard(title: "System") {
                    detailRow(label: "Thermal", value: thermalState, color: thermalColor)
                    rowDivider
                    detailRow(label: "Battery", value: batteryLevel >= 0 ? "\(Int(batteryLevel * 100))% (\(batteryState))" : "N/A", color: InspectorTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount) cores", color: InspectorTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Uptime", value: formatUptime(uptimeSeconds), color: InspectorTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, InspectorTheme.Spacing.lg)
            .padding(.vertical, InspectorTheme.Spacing.md)
        }
        .inspectorBackground()
        .onAppear {
                        UIDevice.current.isBatteryMonitoringEnabled = true
            refreshMetrics()
        }
        .onReceive(timer) { _ in
                        refreshMetrics()
        }
    }

    // MARK: - Chart Section

    private func chartSection(title: String, value: String, peak: String, color: Color, data: [ChartPoint], yLabel: String) -> some View {
        VStack(alignment: .leading, spacing: InspectorTheme.Spacing.sm) {
            // Header
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(.system(size: 11, weight: .semibold))
                    .tracking(0.5)
                    .textCase(.uppercase)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)

                Spacer()

                Text(peak)
                    .font(InspectorTheme.Typography.detail)
                    .foregroundStyle(InspectorTheme.Colors.textTertiary)
            }

            // Value
            Text(value)
                .font(.system(size: 28, weight: .bold, design: .monospaced))
                .foregroundStyle(color)

            // Chart
            if data.count > 1 {
                Chart(data) { point in
                    LineMark(
                        x: .value("Time", point.index),
                        y: .value(yLabel, point.value)
                    )
                    .foregroundStyle(color)
                    .lineStyle(StrokeStyle(lineWidth: 1.5))

                    AreaMark(
                        x: .value("Time", point.index),
                        y: .value(yLabel, point.value)
                    )
                    .foregroundStyle(
                        LinearGradient(
                            colors: [color.opacity(0.3), color.opacity(0.05)],
                            startPoint: .top,
                            endPoint: .bottom
                        )
                    )
                }
                .chartXAxis(.hidden)
                .chartYAxis {
                    AxisMarks(position: .trailing) { value in
                        AxisValueLabel {
                            Text("\(value.as(Int.self) ?? 0)")
                                .font(.system(size: 8))
                                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                        }
                        AxisGridLine()
                            .foregroundStyle(InspectorTheme.Colors.border)
                    }
                }
                .frame(height: 100)
            } else {
                RoundedRectangle(cornerRadius: InspectorTheme.Radius.sm)
                    .fill(InspectorTheme.Colors.surface)
                    .frame(height: 100)
                    .overlay {
                        Text("Collecting data...")
                            .font(InspectorTheme.Typography.detail)
                            .foregroundStyle(InspectorTheme.Colors.textTertiary)
                    }
            }
        }
        .padding(InspectorTheme.Spacing.lg)
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    // MARK: - Small Card

    private func smallCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: InspectorTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(.system(size: 9, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.system(size: 18, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(InspectorTheme.Spacing.md)
        .background(InspectorTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
    }

    // MARK: - Section Card

    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(.system(size: 11, weight: .semibold))
                .tracking(0.5)
                .foregroundStyle(InspectorTheme.Colors.textTertiary)
                .padding(.bottom, InspectorTheme.Spacing.sm)

            VStack(spacing: 0) {
                content()
            }
            .background(InspectorTheme.Colors.surface)
            .clipShape(.rect(cornerRadius: InspectorTheme.Radius.lg))
        }
    }

    private func detailRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(InspectorTheme.Typography.body)
                .foregroundStyle(InspectorTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(InspectorTheme.Typography.code)
                .foregroundStyle(color)
        }
        .padding(.horizontal, InspectorTheme.Spacing.lg)
        .padding(.vertical, InspectorTheme.Spacing.md)
    }

    private var rowDivider: some View {
        Divider().overlay(InspectorTheme.Colors.border)
    }

    // MARK: - Colors

    private var memoryColor: Color {
        if memoryMB > 300 { return InspectorTheme.Colors.error }
        if memoryMB > 150 { return InspectorTheme.Colors.warning }
        return InspectorTheme.Colors.success
    }

    private var cpuColor: Color {
        if cpuPercent > 80 { return InspectorTheme.Colors.error }
        if cpuPercent > 40 { return InspectorTheme.Colors.warning }
        return InspectorTheme.Colors.success
    }

    private var batteryLevelColor: Color {
        guard batteryLevel >= 0 else { return InspectorTheme.Colors.textSecondary }
        if batteryLevel < 0.2 { return InspectorTheme.Colors.error }
        if batteryLevel < 0.5 { return InspectorTheme.Colors.warning }
        return InspectorTheme.Colors.success
    }

    // MARK: - Data Collection

    private func refreshMetrics() {
        memoryMB = memoryUsageMB()
        if memoryMB > memoryPeakMB { memoryPeakMB = memoryMB }
        cpuPercent = cpuUsage()
        threadCount = activeThreadCount()
        (diskFreeMB, diskTotalMB) = diskInfo()
        uptimeSeconds = ProcessInfo.processInfo.systemUptime

        let device = UIDevice.current
        batteryLevel = device.batteryLevel
        batteryState = {
            switch device.batteryState {
            case .charging: return "Charging"
            case .full: return "Full"
            case .unplugged: return "Unplugged"
            default: return "Unknown"
            }
        }()

        let state = ProcessInfo.processInfo.thermalState
        switch state {
        case .nominal: thermalState = "Nominal"; thermalColor = InspectorTheme.Colors.success
        case .fair: thermalState = "Fair"; thermalColor = InspectorTheme.Colors.pending
        case .serious: thermalState = "Serious"; thermalColor = InspectorTheme.Colors.warning
        case .critical: thermalState = "Critical"; thermalColor = InspectorTheme.Colors.error
        @unknown default: thermalState = "Unknown"; thermalColor = InspectorTheme.Colors.textTertiary
        }

        // Update chart history
        tickCount += 1
        memoryHistory.append(ChartPoint(index: tickCount, value: memoryMB))
        cpuHistory.append(ChartPoint(index: tickCount, value: cpuPercent))
        if memoryHistory.count > maxHistory { memoryHistory.removeFirst() }
        if cpuHistory.count > maxHistory { cpuHistory.removeFirst() }
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
        var total: Double = 0
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let result = task_threads(mach_task_self_, &threadsList, &threadsCount)
        if result == KERN_SUCCESS, let threadsList {
            for i in 0..<threadsCount {
                var info = thread_basic_info()
                var infoCount = mach_msg_type_number_t(MemoryLayout<thread_basic_info_data_t>.size / MemoryLayout<integer_t>.size)
                let r = withUnsafeMutablePointer(to: &info) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(i)], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                    }
                }
                if r == KERN_SUCCESS { total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100 }
            }
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadsList), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }
        return total
    }

    private func activeThreadCount() -> Int {
        var threadsList: thread_act_array_t?
        var threadsCount = mach_msg_type_number_t(0)
        let result = task_threads(mach_task_self_, &threadsList, &threadsCount)
        if result == KERN_SUCCESS, let threadsList {
            vm_deallocate(mach_task_self_, vm_address_t(bitPattern: threadsList), vm_size_t(Int(threadsCount) * MemoryLayout<thread_t>.stride))
        }
        return Int(threadsCount)
    }

    private func diskInfo() -> (free: Double, total: Double) {
        guard let attrs = try? FileManager.default.attributesOfFileSystem(forPath: NSHomeDirectory()) else { return (0, 0) }
        let free = (attrs[.systemFreeSize] as? Int64).map(Double.init) ?? 0
        let total = (attrs[.systemSize] as? Int64).map(Double.init) ?? 0
        return (free, total)
    }

    private func formatBytes(_ bytes: Double) -> String {
        ByteCountFormatter.string(fromByteCount: Int64(bytes), countStyle: .file)
    }

    private func formatUptime(_ seconds: TimeInterval) -> String {
        let h = Int(seconds) / 3600
        let m = (Int(seconds) % 3600) / 60
        if h > 0 { return "\(h)h \(m)m" }
        return "\(m)m"
    }
}

// MARK: - Chart Data

private struct ChartPoint: Identifiable {
    let id = UUID()
    let index: Int
    let value: Double
}

// No preview - uses live system APIs that crash XCPreviewAgent
