import Foundation

public extension TracksEventUserType {
    var stringValue: String {
        switch self {
            case .anonymous: return "anonymous"
            case .authenticated: return "authenticated"
            @unknown default: return "unknown"
        }
    }
}
