import Foundation
import Sentry

extension EventLogging {
    func attachLogToEventIfNeeded(event: Event) {

        /// Don't enqueue logs for non-fatal events unless directed to by the delegate
        if event.level != .fatal && !delegate.shouldUploadLogFilesForNonFatalEvents {
            return
        }

        /// We use the previous session's log for fatal errors because that session has presumably ended with the app crashing. If that's not the case,
        /// the hosting app can handle that situation.
        let logFilePath: URL?
        switch event.level {
            case .fatal: logFilePath = dataSource.previousSessionLogPath
            default: logFilePath = dataSource.currentSessionLogPath
        }

        /// Schedule the log file for upload, if available
        if let logFilePath = logFilePath {
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
}
