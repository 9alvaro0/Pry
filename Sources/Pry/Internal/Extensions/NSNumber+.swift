import Foundation

package extension NSNumber {
    package var isBool: Bool {
        return CFBooleanGetTypeID() == CFGetTypeID(self)
    }
}
