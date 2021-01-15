import AutomatticTracks

struct EventLoggingDataProvider {

}

extension EventLoggingDataProvider: EventLoggingDataSource {
    var loggingEncryptionKey: String {
        Secrets.encryptionKey
    }

    var loggingAuthenticationToken: String {
        return ""
    }

    func logFilePath(forErrorLevel: EventLoggingErrorType, at date: Date) -> URL? {
        return nil
    }
}

extension EventLoggingDataProvider: EventLoggingDelegate {
    var shouldUploadLogFiles: Bool {
        return true
    }
}
