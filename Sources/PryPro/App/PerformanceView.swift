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
    @State private var thermalColor: Color = PryTheme.Colors.success
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
            VStack(spacing: PryTheme.Spacing.lg) {
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
                    GridItem(.flexible(), spacing: PryTheme.Spacing.sm),
                    GridItem(.flexible(), spacing: PryTheme.Spacing.sm)
                ], spacing: PryTheme.Spacing.sm) {
                    smallCard(title: "Threads", value: "\(threadCount)", color: PryTheme.Colors.accent)
                    smallCard(title: "Thermal", value: thermalState, color: thermalColor)
                    smallCard(title: "Battery", value: batteryLevel >= 0 ? "\(Int(batteryLevel * 100))%" : "N/A", color: batteryLevelColor)
                    smallCard(title: "Uptime", value: formatUptime(uptimeSeconds), color: PryTheme.Colors.textSecondary)
                }

                // Detail sections
                sectionCard(title: "Memory") {
                    detailRow(label: "Used", value: String(format: "%.1f MB", memoryMB), color: memoryColor)
                    rowDivider
                    detailRow(label: "Peak (session)", value: String(format: "%.1f MB", memoryPeakMB), color: PryTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Device RAM", value: formatBytes(Double(ProcessInfo.processInfo.physicalMemory)), color: PryTheme.Colors.textSecondary)
                }

                sectionCard(title: "Storage") {
                    detailRow(label: "Free", value: formatBytes(diskFreeMB), color: PryTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Total", value: formatBytes(diskTotalMB), color: PryTheme.Colors.textSecondary)
                    if diskTotalMB > 0 {
                        rowDivider
                        let pct = ((diskTotalMB - diskFreeMB) / diskTotalMB) * 100
                        detailRow(label: "Used", value: String(format: "%.0f%%", pct), color: pct > 90 ? PryTheme.Colors.error : PryTheme.Colors.textSecondary)
                    }
                }

                sectionCard(title: "System") {
                    detailRow(label: "Thermal", value: thermalState, color: thermalColor)
                    rowDivider
                    detailRow(label: "Battery", value: batteryLevel >= 0 ? "\(Int(batteryLevel * 100))% (\(batteryState))" : "N/A", color: PryTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Processors", value: "\(ProcessInfo.processInfo.activeProcessorCount) cores", color: PryTheme.Colors.textSecondary)
                    rowDivider
                    detailRow(label: "Uptime", value: formatUptime(uptimeSeconds), color: PryTheme.Colors.textSecondary)
                }
            }
            .padding(.horizontal, PryTheme.Spacing.lg)
            .padding(.vertical, PryTheme.Spacing.md)
        }
        .pryBackground()
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
        VStack(alignment: .leading, spacing: PryTheme.Spacing.sm) {
            // Header
            HStack(alignment: .lastTextBaseline) {
                Text(title)
                    .font(PryTheme.Typography.sectionLabel)
                    .tracking(PryTheme.Text.tracking)
                    .textCase(.uppercase)
                    .foregroundStyle(PryTheme.Colors.textTertiary)

                Spacer()

                Text(peak)
                    .font(PryTheme.Typography.detail)
                    .foregroundStyle(PryTheme.Colors.textTertiary)
            }

            // Value
            Text(value)
                .font(.system(size: PryTheme.FontSize.emptyState, weight: .bold, design: .monospaced))
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
                            colors: [color.opacity(PryTheme.Opacity.moderate), color.opacity(PryTheme.Opacity.subtle)],
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
                                .font(PryTheme.Typography.chartLabel)
                                .foregroundStyle(PryTheme.Colors.textTertiary)
                        }
                        AxisGridLine()
                            .foregroundStyle(PryTheme.Colors.border)
                    }
                }
                .frame(height: PryTheme.Size.chartHeight)
            } else {
                RoundedRectangle(cornerRadius: PryTheme.Radius.sm)
                    .fill(PryTheme.Colors.surface)
                    .frame(height: PryTheme.Size.chartHeight)
                    .overlay {
                        Text("Collecting data...")
                            .font(PryTheme.Typography.detail)
                            .foregroundStyle(PryTheme.Colors.textTertiary)
                    }
            }
        }
        .padding(PryTheme.Spacing.lg)
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
    }

    // MARK: - Small Card

    private func smallCard(title: String, value: String, color: Color) -> some View {
        VStack(spacing: PryTheme.Spacing.xs) {
            Text(title.uppercased())
                .font(.system(size: PryTheme.FontSize.badge, weight: .semibold))
                .tracking(PryTheme.Text.tracking)
                .foregroundStyle(PryTheme.Colors.textTertiary)
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(value)
                .font(.system(size: PryTheme.FontSize.largeMetric, weight: .bold, design: .monospaced))
                .foregroundStyle(color)
                .lineLimit(1)
                .minimumScaleFactor(0.6)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(PryTheme.Spacing.md)
        .background(PryTheme.Colors.surface)
        .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
    }

    // MARK: - Section Card

    private func sectionCard(title: String, @ViewBuilder content: () -> some View) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(title.uppercased())
                .font(PryTheme.Typography.sectionLabel)
                .tracking(PryTheme.Text.tracking)
                .foregroundStyle(PryTheme.Colors.textTertiary)
                .padding(.bottom, PryTheme.Spacing.sm)

            VStack(spacing: 0) {
                content()
            }
            .background(PryTheme.Colors.surface)
            .clipShape(.rect(cornerRadius: PryTheme.Radius.lg))
        }
    }

    private func detailRow(label: String, value: String, color: Color) -> some View {
        HStack {
            Text(label)
                .font(PryTheme.Typography.body)
                .foregroundStyle(PryTheme.Colors.textSecondary)
            Spacer()
            Text(value)
                .font(PryTheme.Typography.code)
                .foregroundStyle(color)
        }
        .padding(.horizontal, PryTheme.Spacing.lg)
        .padding(.vertical, PryTheme.Spacing.md)
    }

    private var rowDivider: some View {
        Divider().overlay(PryTheme.Colors.border)
    }

    // MARK: - Colors

    private var memoryColor: Color {
        if memoryMB > 300 { return PryTheme.Colors.error }
        if memoryMB > 150 { return PryTheme.Colors.warning }
        return PryTheme.Colors.success
    }

    private var cpuColor: Color {
        if cpuPercent > 80 { return PryTheme.Colors.error }
        if cpuPercent > 40 { return PryTheme.Colors.warning }
        return PryTheme.Colors.success
    }

    private var batteryLevelColor: Color {
        guard batteryLevel >= 0 else { return PryTheme.Colors.textSecondary }
        if batteryLevel < 0.2 { return PryTheme.Colors.error }
        if batteryLevel < 0.5 { return PryTheme.Colors.warning }
        return PryTheme.Colors.success
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
        case .nominal: thermalState = "Nominal"; thermalColor = PryTheme.Colors.success
        case .fair: thermalState = "Fair"; thermalColor = PryTheme.Colors.pending
        case .serious: thermalState = "Serious"; thermalColor = PryTheme.Colors.warning
        case .critical: thermalState = "Critical"; thermalColor = PryTheme.Colors.error
        @unknown default: thermalState = "Unknown"; thermalColor = PryTheme.Colors.textTertiary
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
                let result = withUnsafeMutablePointer(to: &info) {
                    $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                        thread_info(threadsList[Int(i)], thread_flavor_t(THREAD_BASIC_INFO), $0, &infoCount)
                    }
                }
                if result == KERN_SUCCESS { total += Double(info.cpu_usage) / Double(TH_USAGE_SCALE) * 100 }
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
