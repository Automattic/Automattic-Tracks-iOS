import Foundation

public enum EventLoggingFileUploadError: Error, LocalizedError {
    case httpError(String)
    case fileMissing

    public var errorDescription: String? {
        switch self {
            case .httpError(let message): return message
            case .fileMissing: return NSLocalizedString(
                "File not found", comment: "A message indicating that a file queued for upload could not be found"
            )
        }
    }
}
