import AutomatticTracks

struct EventLoggingDataProvider { }

extension EventLoggingDataProvider: EventLoggingDataSource {
    var loggingEncryptionKey: String {
        Secrets.encryptionKey
    }

    var loggingAuthenticationToken: String {
        return "--invalid-token--"
    }

    func logFilePath(forErrorLevel: EventLoggingErrorType, at date: Date) -> URL? {
        /// We don't need to associate log files with crashes after the fact for the demo app, so pretend we have none
        return nil
    }
}

extension EventLoggingDataProvider: EventLoggingDelegate {

    /// Always opt-in to uploading log files
    var shouldUploadLogFiles: Bool {
        return true
    }
}
