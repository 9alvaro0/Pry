import Foundation

extension TimeInterval {
    var formattedDuration: String {
        if self < 1 {
            return String(format: "%.0fms", self * 1000)
        } else {
            return String(format: "%.2fs", self)
        }
    }
}

extension Optional where Wrapped == TimeInterval {
    var formattedDuration: String {
        guard let value = self else { return "-" }
        return value.formattedDuration
    }
}
