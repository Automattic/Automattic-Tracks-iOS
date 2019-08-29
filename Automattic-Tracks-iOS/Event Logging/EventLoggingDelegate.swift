import Foundation

public protocol EventLoggingDelegate {
    /// The event logging system will call this delegate property prior to attempting to upload, giving the application a chance to determine
    /// whether or not the upload should proceed. If this is not overridden, the default is `false`.
    var shouldUploadLogFiles: Bool { get }

    /// The event logging system will call this delegate method each time a log file starts uploading.
    func didStartUploadingLog(_ log: LogFile)

    /// The event logging system will call this delegate method if a log file upload is cancelled by the delegate.
    func uploadCancelledByDelegate(_ log: LogFile)

    /// The event logging system will call this delegate method if a log file fails to upload.
    func uploadFailed(withError: Error, forLog: LogFile)

    /// The event logging system will call this delegate method each time a log file finishes uploading.
    func didFinishUploadingLog(_ log: LogFile)
}

/// Default implementations for EventLoggingDelegate
public extension EventLoggingDelegate {

    var shouldUploadLogFiles: Bool {
        return false // Use a privacy-preserving default
    }

    // Empty default implementations allow the developer to only implement these if they need them
    func didStartUploadingLog(_ log: LogFile) {}
    func uploadCancelledByDelegate(_ log: LogFile) {}
    func uploadFailed(withError error: Error, forLog log: LogFile) {}
    func didFinishUploadingLog(_ log: LogFile) {}
}
