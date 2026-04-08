import Foundation

/// Network condition simulation presets.
public enum NetworkThrottle: String, CaseIterable, Codable, Sendable {
    case none = "None"
    case slow3G = "Slow 3G"
    case fast3G = "Fast 3G"
    case lossy = "Lossy"
    case offline = "Offline"

    /// Delay in seconds before each request starts.
    public var delay: TimeInterval {
        switch self {
        case .none: 0
        case .slow3G: 2.0
        case .fast3G: 0.5
        case .lossy: 0.3
        case .offline: 0
        }
    }

    /// Probability of request failure (0.0 - 1.0).
    public var failureRate: Double {
        switch self {
        case .none: 0
        case .slow3G: 0
        case .fast3G: 0
        case .lossy: 0.3
        case .offline: 1.0
        }
    }

    public var description: String {
        switch self {
        case .none: "No throttling"
        case .slow3G: "2s delay per request"
        case .fast3G: "500ms delay per request"
        case .lossy: "300ms delay, 30% failure"
        case .offline: "All requests fail"
        }
    }
}
