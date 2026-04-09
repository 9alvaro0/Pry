import Foundation

@_spi(PryPro) public extension TimeInterval {
    @_spi(PryPro) public var formattedDuration: String {
        if self < 1 {
            return String(format: "%.0fms", self * 1000)
        } else {
            return String(format: "%.2fs", self)
        }
    }
}

@_spi(PryPro) public extension Optional where Wrapped == TimeInterval {
    @_spi(PryPro) public var formattedDuration: String {
        guard let value = self else { return "-" }
        return value.formattedDuration
    }
}
