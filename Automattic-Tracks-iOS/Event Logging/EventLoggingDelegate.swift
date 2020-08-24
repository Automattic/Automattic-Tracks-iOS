import Foundation

public protocol EventLoggingDelegate {
    /// The event logging system will call this delegate property prior to attempting to upload, giving the application a chance to determine
    /// whether or not the upload should proceed. If this is not overridden, the default is `false`.
    var shouldUploadLogFiles: Bool { get }

    /// Should the event logging system upload log files for non-fatal events (such as logging an `NSError`)?
    var shouldUploadLogFilesForNonFatalEvents: Bool { get }

    /// The event logging system will call this delegate method each time a log file is added to the queue..
    func didQueueLogForUpload(_ log: LogFile)

    /// The event logging system will call this delegate method each time a log file starts uploading.
    func didStartUploadingLog(_ log: LogFile)

    /// The event logging system will call this delegate method if a log file upload is cancelled by the delegate.
    func uploadCancelledByDelegate(_ log: LogFile)

    /// The event logging system will call this delegate method if a log file fails to upload.
    /// It may be called prior to upload starting if the file is missing, and is called after to the `upload` callback.
    func uploadFailed(withError: Error, forLog: LogFile)

    /// The event logging system will call this delegate method each time a log file finishes uploading.
    /// It is called after to the `upload` callback.
    func didFinishUploadingLog(_ log: LogFile)
}

/// Default implementations for EventLoggingDelegate
public extension EventLoggingDelegate {

    var shouldUploadLogFiles: Bool {
        return false // Use a privacy-preserving default
    }

    var shouldUploadLogFilesForNonFatalEvents: Bool {
        return false // By default, keep the traffic level down
    }

    // Empty default implementations allow the developer to only implement these if they need them
    func didQueueLogForUpload(_ log: LogFile) {}
    func didStartUploadingLog(_ log: LogFile) {}
    func uploadCancelledByDelegate(_ log: LogFile) {}
    func uploadFailed(withError error: Error, forLog log: LogFile) {}
    func didFinishUploadingLog(_ log: LogFile) {}
}
