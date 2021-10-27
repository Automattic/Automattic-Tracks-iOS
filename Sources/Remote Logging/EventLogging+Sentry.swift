import Foundation
import Sentry

#if SWIFT_PACKAGE
import AutomatticTracksModel
import AutomatticTracksModelObjC
import AutomatticEncryptedLogs
#endif

public extension EventLoggingDelegate {
    func logError(_ error: Error, userInfo: [String: Any]?) {
        CrashLogging.Internals.crashLogging?.logError(error, userInfo: userInfo)
    }
}

extension EventLogging {
    func attachLogToEventIfNeeded(event: Event) {

        /// Don't enqueue logs for non-fatal events unless directed to by the delegate
        if event.level != .fatal && !delegate.shouldUploadLogFilesForNonFatalEvents {
            TracksLogDebug("📜 Cancelling event log attachment – level is \(String(describing: event.level))")
            return
        }

        /// Allow the hosting app to determine the most appropriate log file to send for the error type. For example, in an application using
        /// session-based file logging, the newest log file would be the current session, which is appropriate for debugging logs. However,
        /// the previous session's log file is the correct one for a crash, because when the crash is sent there will already be a new log
        /// file for the current session. Other apps may use time-based logs, in which case the same log would be the correct one.
        ///
        /// We also pass the timestamp for the event, as that can be useful for determining the correct log file.
        guard let logFilePath = dataSource.logFilePath(forErrorLevel: event.errorType, at: event.timestamp) else {
            TracksLogDebug("📜 Unable to locate a log file to attach")
            return
        }

        /// Schedule the log file for upload, if available
        do {
            let logFile = LogFile(url: logFilePath)
            try enqueueLogForUpload(log: logFile)
            event.logID = logFile.uuid
        }
        catch let err {
            CrashLogging.Internals.crashLogging?.logError(err)
        }
    }
}

extension Event {
    var errorType: EventLoggingErrorType {
        switch self.level {
        case .fatal:
            return .fatal
        case .error, .warning, .info, .debug, .none:
            return .debug
        @unknown default:
            return .debug
        }
    }


    private static let logIDKey = "logID"

    var logID: String? {
        get {
            return self.extra?[Event.logIDKey] as? String
        }
        set {
            self.extra?[Event.logIDKey] = newValue
        }
    }
}
