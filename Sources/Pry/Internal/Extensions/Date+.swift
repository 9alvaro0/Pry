import Foundation

@_spi(PryPro) public extension Date {

    @_spi(PryPro) public func formatFullTimestamp() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        return formatter.string(from: self)
    }

    @_spi(PryPro) public var formattedTimestamp: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "HH:mm:ss.SSS"
        return formatter.string(from: self)
    }

    @_spi(PryPro) public var relativeTimestamp: String {
        let seconds = -timeIntervalSinceNow
        switch seconds {
        case ..<2:    return "just now"
        case ..<60:   return "\(Int(seconds))s ago"
        case ..<3600: return "\(Int(seconds / 60))m ago"
        case ..<86400: return "\(Int(seconds / 3600))h ago"
        default:
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d, HH:mm"
            return formatter.string(from: self)
        }
    }
}
