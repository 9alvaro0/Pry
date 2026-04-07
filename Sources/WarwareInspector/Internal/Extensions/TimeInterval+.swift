import Foundation

extension Optional where Wrapped == TimeInterval {
    var formattedDuration: String {
        guard let value = self else { return "-" }
        if value < 1 {
            return String(format: "%.0fms", value * 1000)
        } else {
            return String(format: "%.2fs", value)
        }
    }
}
