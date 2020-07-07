import Foundation
import Sentry

public enum EventLoggingErrorType {
    case fatal
    case debug
}

extension EventLogging {
    func attachLogToEventIfNeeded(event: Event) {

        /// Don't enqueue logs for non-fatal events unless directed to by the delegate
        if event.level != .fatal && !delegate.shouldUploadLogFilesForNonFatalEvents {
            return
        }

        /// Allow the hosting app to determine the most appropriate log file to send for the error type. For example, in an application using
        /// session-based file logging, the newest log file would be the current session, which is appropriate for debugging logs. However,
        /// the previous session's log file is the correct one for a crash, because when the crash is sent there will already be a new log
        /// file for the current session. Other apps may use time-based logs, in which case the same log would be the correct one.
        ///
        /// We also pass the timestamp for the event, as that can be useful for determining the correct log file.
        guard let logFilePath = dataSource.logFilePath(forErrorLevel: event.errorType, at: event.timestamp) else {
            return
        }

        /// Schedule the log file for upload, if available
        do {
            let logFile = LogFile(url: logFilePath)
            try enqueueLogForUpload(log: logFile)
            event.logID = logFile.uuid
        }
        catch let err {
            CrashLogging.logError(err)
        }
    }
}

extension Event {
    var errorType: EventLoggingErrorType {
        switch self.level {
        case .fatal:
            return .fatal
        case .error, .warning, .info, .debug:
            return .debug
        @unknown default:
            return .debug
        }
    }
}
