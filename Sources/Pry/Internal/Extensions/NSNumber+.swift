import Foundation

@_spi(PryPro) public extension NSNumber {
    @_spi(PryPro) public var isBool: Bool {
        return CFBooleanGetTypeID() == CFGetTypeID(self)
    }
}
