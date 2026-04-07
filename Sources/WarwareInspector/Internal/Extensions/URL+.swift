import Foundation

extension URL: @retroactive Identifiable {
    public var id: URL { self }
}
