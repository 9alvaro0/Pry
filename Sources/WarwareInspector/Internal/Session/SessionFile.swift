import Foundation
import UIKit

/// Represents a complete inspector session that can be exported/imported.
struct SessionFile: Codable {
    let version: Int
    let exportedAt: Date
    let device: DeviceInfo
    let entries: Entries

    struct DeviceInfo: Codable {
        let name: String
        let model: String
        let systemVersion: String
        let appName: String?
        let appVersion: String?
        let appBuild: String?
    }

    struct Entries: Codable {
        let network: [NetworkEntry]
        let logs: [LogEntry]
        let deeplinks: [DeeplinkEntry]
        let pushNotifications: [PushNotificationEntry]
    }
}

/// Exports and imports .warware session files.
enum SessionFileManager {

    static let fileExtension = "warware"
    private static let currentVersion = 1

    // MARK: - Export

    /// Creates a .warware file from the current store and returns the temporary file URL.
    static func export(store: InspectorStore) -> URL? {
        let info = Bundle.main.infoDictionary
        let device = UIDevice.current

        let session = SessionFile(
            version: currentVersion,
            exportedAt: Date(),
            device: SessionFile.DeviceInfo(
                name: device.name,
                model: device.model,
                systemVersion: device.systemVersion,
                appName: info?["CFBundleName"] as? String,
                appVersion: info?["CFBundleShortVersionString"] as? String,
                appBuild: info?["CFBundleVersion"] as? String
            ),
            entries: SessionFile.Entries(
                network: store.networkEntries,
                logs: store.logEntries,
                deeplinks: store.deeplinkEntries,
                pushNotifications: store.pushNotificationEntries
            )
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.sortedKeys]

        guard let jsonData = try? encoder.encode(session) else { return nil }

        // Compress with gzip for smaller files
        guard let compressed = try? (jsonData as NSData).compressed(using: .zlib) as Data else {
            return writeToTemp(data: jsonData)
        }

        return writeToTemp(data: compressed)
    }

    // MARK: - Import

    /// Loads a .warware file and returns a read-only store with the session data.
    static func importSession(from url: URL) -> (store: InspectorStore, metadata: SessionFile.DeviceInfo)? {
        guard let data = try? Data(contentsOf: url) else { return nil }

        // Try decompressing (may be compressed or raw JSON)
        let jsonData: Data
        if let decompressed = try? (data as NSData).decompressed(using: .zlib) as Data {
            jsonData = decompressed
        } else {
            jsonData = data
        }

        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601

        guard let session = try? decoder.decode(SessionFile.self, from: jsonData) else { return nil }

        let store = InspectorStore()

        // Load entries in chronological order (oldest first, since addEntry inserts at 0)
        for entry in session.entries.network.reversed() {
            store.addNetworkEntry(entry)
        }
        for entry in session.entries.logs.reversed() {
            store.addLogEntry(entry)
        }
        for entry in session.entries.deeplinks.reversed() {
            store.addDeeplinkEntry(entry)
        }
        for entry in session.entries.pushNotifications.reversed() {
            store.addPushNotification(entry)
        }

        return (store, session.device)
    }

    // MARK: - Helpers

    private static func writeToTemp(data: Data) -> URL? {
        let filename = "session_\(DateFormatter.fileTimestamp.string(from: Date())).\(fileExtension)"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        do {
            try data.write(to: url)
            return url
        } catch {
            return nil
        }
    }
}

private extension DateFormatter {
    static let fileTimestamp: DateFormatter = {
        let f = DateFormatter()
        f.dateFormat = "yyyyMMdd_HHmmss"
        return f
    }()
}
