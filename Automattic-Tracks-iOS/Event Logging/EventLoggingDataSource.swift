import Foundation

public struct EventLoggingDefaults {
    public static var defaultQueueStoragePath: URL {
        let paths = NSSearchPathForDirectoriesInDomains(.applicationSupportDirectory, .userDomainMask, true)
        let applicationSupportDirectory = URL(fileURLWithPath: paths.first!)
        let demoSupportDirectory = applicationSupportDirectory.appendingPathComponent(Bundle.main.bundleIdentifier ?? "tracks")
        let logsRoot = demoSupportDirectory.appendingPathComponent("log-upload-queue")

        return logsRoot
    }
}

public protocol EventLoggingDataSource {
    /// A base-64 encoded representation of the encryption key.
    var loggingEncryptionKey: String { get }

    /// The URL to the upload endpoint for encrypted logs.
    var logUploadURL: URL { get }

    /// The path to log upload queue storage
    var logUploadQueueStorageURL: URL { get }

    /// The authentication token used for encrypted log upload
    var loggingAuthenticationToken: String { get }

    /// Provides the log file corresponding to a given error type (if it exists)
    func logFilePath(forErrorLevel: EventLoggingErrorType, at date: Date) -> URL?
}

public extension EventLoggingDataSource {
    // The default implementation points to the WP.com private encrypted logging API
    var logUploadURL: URL {
        return URL(string: "https://public-api.wordpress.com/rest/v1.1/encrypted-logging")!
    }

    // The default implementation points to a folder called `log-upload-queue` in the users' documents directory
    var logUploadQueueStorageURL: URL {
        EventLoggingDefaults.defaultQueueStoragePath
    }
}
