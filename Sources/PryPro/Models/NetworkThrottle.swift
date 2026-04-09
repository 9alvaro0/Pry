import Foundation

/// Network condition simulation presets.
public enum NetworkThrottle: String, CaseIterable, Codable, Sendable {
    /// No throttling applied.
    case none = "None"
    /// Simulates a slow 3G connection with a 2-second delay.
    case slow3G = "Slow 3G"
    /// Simulates a fast 3G connection with a 500ms delay.
    case fast3G = "Fast 3G"
    /// Simulates a lossy connection with 300ms delay and 30% failure rate.
    case lossy = "Lossy"
    /// Simulates offline mode where all requests fail.
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

    /// A human-readable description of the throttle behavior.
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
