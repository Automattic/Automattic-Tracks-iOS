import Foundation
import AutomatticTracksInternalLogging
import AutomatticTracksModelObjC

public enum EventLoggingFileUploadError: Error, LocalizedError {
    /// HTTP Errors should receive the error code, a localized error string, and the HTTP status code
    case httpError(String, String, Int)
    case fileMissing
    case cancelledByDelegate

    public var errorDescription: String? {
        switch self {
            case .httpError(let message, _, _): return message
            case .fileMissing: return NSLocalizedString(
                "File not found",
                comment: "A message indicating that a file queued for upload could not be found"
            )
            case .cancelledByDelegate: return NSLocalizedString(
                "System Cancelled Upload",
                comment: "A message indicating that a file queued for upload was cancelled by the system"
            )
        }
    }
}

extension EventLoggingFileUploadError: CustomNSError {

    public static var errorDomain: String {
        return TracksErrorDomain
    }

    public var errorCode: Int {
        switch self {
            case .httpError(_, _, let statusCode): return statusCode
            case .fileMissing: return TracksErrorCode.fileMissing.rawValue
            case .cancelledByDelegate: return TracksErrorCode.operationCancelled.rawValue
        }
    }

    public var failureReason: String? {
        switch self {
            case .httpError(_, let message, _): return message
            default: return nil
        }
    }
}
