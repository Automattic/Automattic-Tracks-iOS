import Foundation
import Sodium

#if SWIFT_PACKAGE
@testable import AutomatticTracksEventLogging
@testable import AutomatticRemoteLogging
#else
@testable import AutomatticTracks
#endif

typealias LogFileCallback = (LogFile) -> ()
typealias ErrorWithLogFileCallback = (Error, LogFile) -> ()

enum MockError: Error {
    case generic
}

class MockEventLoggingDataSource: EventLoggingDataSource {
    private(set) var loggingEncryptionKey: String
    private(set) var logUploadURL: URL
    private(set) var logUploadQueueStorageURL: URL
    private(set) var loggingAuthenticationToken: String = ""
    private let sessionLogPath: URL?

    init(
        encryptionKey: String = "foo",
        sessionLogPath: URL? = nil,
        logUploadUrl: URL = URL(string: "example.com")!,
        queueUrl: URL = FileManager.default.documentsDirectory.appendingPathComponent(UUID().uuidString)) {
        self.loggingEncryptionKey = encryptionKey
        self.logUploadURL = logUploadUrl
        self.logUploadQueueStorageURL = queueUrl
        self.sessionLogPath = sessionLogPath
    }

    func logFilePath(forErrorLevel: EventLoggingErrorType, at date: Date) -> URL? {
        return sessionLogPath
    }

    func withLogUploadUrl(_ url: URL) -> Self {
        self.logUploadURL = url
        return self
    }

    func withEncryptionKey() -> Self {
        let keyPair = Sodium().box.keyPair()!
        self.loggingEncryptionKey = Data(keyPair.publicKey).base64EncodedString()
        return self
    }

    func withAuthenticationToken(_ token: String) -> Self {
        self.loggingAuthenticationToken = token
        return self
    }
}

class MockEventLoggingDelegate: EventLoggingDelegate {

    private(set) var didStartUploadingTriggered = false
    private(set) var didStartUploadingCallback: LogFileCallback?
    func withDidStartUploadingCallback(_ callback: LogFileCallback?) -> Self {
        self.didStartUploadingCallback = callback
        return self
    }

    func didStartUploadingLog(_ log: LogFile) {
        didStartUploadingTriggered = true
        didStartUploadingCallback?(log)
    }

    private(set) var didFinishUploadingTriggered = false
    private(set) var didFinishUploadingCallback: LogFileCallback?
    func withDidFinishUploadingCallback(_ callback: @escaping LogFileCallback) -> Self {
        self.didFinishUploadingCallback = callback
        return self
    }

    func didFinishUploadingLog(_ log: LogFile) {
        didFinishUploadingTriggered = true
        didFinishUploadingCallback?(log)
    }

    private(set) var uploadCancelledByDelegateTriggered = false
    private(set) var uploadCancelledByDelegateCallback: LogFileCallback?
    func withUploadCancelledCallback(_ callback: @escaping LogFileCallback) -> Self {
        self.uploadCancelledByDelegateCallback = callback
        return self
    }

    func uploadCancelledByDelegate(_ log: LogFile) {
        uploadCancelledByDelegateTriggered = true
        uploadCancelledByDelegateCallback?(log)
    }

    private(set) var uploadFailedTriggered = false
    private(set) var uploadFailedCallback: ErrorWithLogFileCallback?
    func withUploadFailedCallback(_ callback: @escaping ErrorWithLogFileCallback) -> Self {
        self.uploadFailedCallback = callback
        return self
    }

    func uploadFailed(withError error: Error, forLog log: LogFile) {
        uploadFailedTriggered = true
        uploadFailedCallback?(error, log)
    }

    private(set) var shouldUploadLogFiles: Bool = true
    func withShouldUploadLogFilesValue(_ newValue: Bool) -> Self {
        self.shouldUploadLogFiles = newValue
        return self
    }
}

class MockEventLoggingNetworkService: EventLoggingNetworkService {
    private(set) var shouldSucceed: Bool

    init(shouldSucceed: Bool = true) {
        self.shouldSucceed = shouldSucceed
    }

    override func uploadFile(request: URLRequest, fileURL: URL, completion: @escaping EventLoggingNetworkService.ResultCallback) {
        shouldSucceed ? completion(.success(Data())) : completion(.failure(MockError.generic))
    }
}
