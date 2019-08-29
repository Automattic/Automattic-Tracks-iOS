import Foundation

public enum UploadError: Error, LocalizedError {
    case httpError(String)
    case fileMissing

    public var errorDescription: String?{
        switch self {
            case .httpError(let message): return message
            case .fileMissing: return "File not found"
        }
    }
}
