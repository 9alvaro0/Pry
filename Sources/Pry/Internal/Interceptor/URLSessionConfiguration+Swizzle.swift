import Foundation
import ObjectiveC

extension URLSessionConfiguration {

    /// Swizzles the `protocolClasses` getter to automatically inject
    /// `PryURLProtocol` into every URLSessionConfiguration.
    /// This ensures ALL URLSessions (not just .shared) are intercepted.
    static func swizzleDefaultConfiguration() {
        let originalSelector = #selector(getter: URLSessionConfiguration.protocolClasses)
        let swizzledSelector = #selector(getter: URLSessionConfiguration.pry_protocolClasses)

        guard
            let originalMethod = class_getInstanceMethod(Self.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(Self.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc
    private var pry_protocolClasses: [AnyClass]? {
        // This calls the original (swizzled) getter
        guard var protocols = self.pry_protocolClasses else {
            return [PryURLProtocol.self]
        }

        // Only inject if not already present
        if !protocols.contains(where: { $0 == PryURLProtocol.self }) {
            protocols.insert(PryURLProtocol.self, at: 0)
        }

        return protocols
    }
}
