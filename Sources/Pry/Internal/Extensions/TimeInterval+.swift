import Foundation

package extension TimeInterval {
    package var formattedDuration: String {
        if self < 1 {
            return String(format: "%.0fms", self * 1000)
        } else {
            return String(format: "%.2fs", self)
        }
    }
}

package extension Optional where Wrapped == TimeInterval {
    package var formattedDuration: String {
        guard let value = self else { return "-" }
        return value.formattedDuration
    }
}
