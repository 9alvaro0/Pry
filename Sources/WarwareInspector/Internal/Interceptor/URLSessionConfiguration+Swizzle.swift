import Foundation
import ObjectiveC

extension URLSessionConfiguration {

    /// Swizzles the `protocolClasses` getter to automatically inject
    /// `InspectorURLProtocol` into every URLSessionConfiguration.
    /// This ensures ALL URLSessions (not just .shared) are intercepted.
    static func swizzleDefaultConfiguration() {
        let originalSelector = #selector(getter: URLSessionConfiguration.protocolClasses)
        let swizzledSelector = #selector(getter: URLSessionConfiguration.inspector_protocolClasses)

        guard
            let originalMethod = class_getInstanceMethod(Self.self, originalSelector),
            let swizzledMethod = class_getInstanceMethod(Self.self, swizzledSelector)
        else { return }

        method_exchangeImplementations(originalMethod, swizzledMethod)
    }

    @objc
    private var inspector_protocolClasses: [AnyClass]? {
        // This calls the original (swizzled) getter
        guard var protocols = self.inspector_protocolClasses else {
            return [InspectorURLProtocol.self]
        }

        // Only inject if not already present
        if !protocols.contains(where: { $0 == InspectorURLProtocol.self }) {
            protocols.insert(InspectorURLProtocol.self, at: 0)
        }

        return protocols
    }
}
