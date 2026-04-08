import Foundation
import UIKit

/// Automatically logs app lifecycle events to the console.
final class LifecycleInterceptor: @unchecked Sendable {

    nonisolated(unsafe) static var store: InspectorStore?

    static func install() {
        let nc = NotificationCenter.default

        nc.addObserver(forName: UIApplication.didBecomeActiveNotification, object: nil, queue: .main) { _ in
            log("App became active", type: .info)
        }

        nc.addObserver(forName: UIApplication.willResignActiveNotification, object: nil, queue: .main) { _ in
            log("App will resign active", type: .warning)
        }

        nc.addObserver(forName: UIApplication.didEnterBackgroundNotification, object: nil, queue: .main) { _ in
            log("App entered background", type: .warning)
        }

        nc.addObserver(forName: UIApplication.willEnterForegroundNotification, object: nil, queue: .main) { _ in
            log("App will enter foreground", type: .info)
        }

        nc.addObserver(forName: UIApplication.didReceiveMemoryWarningNotification, object: nil, queue: .main) { _ in
            log("Memory warning received", type: .error)
        }

        nc.addObserver(forName: UIApplication.significantTimeChangeNotification, object: nil, queue: .main) { _ in
            log("Significant time change", type: .debug)
        }

        nc.addObserver(forName: ProcessInfo.thermalStateDidChangeNotification, object: nil, queue: .main) { _ in
            let state = ProcessInfo.processInfo.thermalState
            let desc: String = switch state {
            case .nominal: "Nominal"
            case .fair: "Fair"
            case .serious: "Serious"
            case .critical: "Critical"
            @unknown default: "Unknown"
            }
            let type: LogType = state == .critical || state == .serious ? .error : .warning
            log("Thermal state changed: \(desc)", type: type)
        }
    }

    private static func log(_ message: String, type: LogType) {
        let entry = LogEntry(
            timestamp: Date(),
            type: type,
            message: message,
            file: "System",
            function: "Lifecycle",
            line: nil,
            additionalInfo: ["source": "lifecycle"]
        )
        Task { @MainActor in
            store?.addLogEntry(entry)
        }
    }
}
