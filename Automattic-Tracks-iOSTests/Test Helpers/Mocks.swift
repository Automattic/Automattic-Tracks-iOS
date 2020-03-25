import Foundation
import Sodium
@testable import AutomatticTracks

typealias LogFileCallback = (LogFile) -> ()
typealias ErrorWithLogFileCallback = (Error, LogFile) -> ()

enum MockError: Error {
    case generic
}

class MockEventLoggingDataSource: EventLoggingDataSource {

    var loggingEncryptionKey: String = "foo"
    var previousSessionLogPath: URL? = nil

    /// Overrides for logUploadURL
    var _logUploadURL: URL = URL(string: "example.com")!
    var logUploadURL: URL {
        return _logUploadURL
    }

    func setLogUploadUrl(_ url: URL) {
        self._logUploadURL = url
    }

    func withEncryptionKeys() -> Self {
        let keyPair = Sodium().box.keyPair()!
        loggingEncryptionKey = Data(keyPair.publicKey).base64EncodedString()
        return self
    }
}

class MockEventLoggingDelegate: EventLoggingDelegate {

    var didStartUploadingTriggered = false
    var didStartUploadingCallback: LogFileCallback?

    func didStartUploadingLog(_ log: LogFile) {
        didStartUploadingTriggered = true
        didStartUploadingCallback?(log)
    }

    var didFinishUploadingTriggered = false
    var didFinishUploadingCallback: LogFileCallback?

    func didFinishUploadingLog(_ log: LogFile) {
        didFinishUploadingTriggered = true
        didFinishUploadingCallback?(log)
    }

    var uploadCancelledByDelegateTriggered = false
    var uploadCancelledByDelegateCallback: LogFileCallback?
    
    func uploadCancelledByDelegate(_ log: LogFile) {
        uploadCancelledByDelegateTriggered = true
        uploadCancelledByDelegateCallback?(log)
    }

    var uploadFailedTriggered = false
    var uploadFailedCallback: ErrorWithLogFileCallback?

    func uploadFailed(withError error: Error, forLog log: LogFile) {
        uploadFailedTriggered = true
        uploadFailedCallback?(error, log)
    }

    func setShouldUploadLogFiles(_ newValue: Bool) {
        _shouldUploadLogFiles = newValue
    }

    private var _shouldUploadLogFiles: Bool = true
    var shouldUploadLogFiles: Bool {
        return _shouldUploadLogFiles
    }
}

class MockEventLoggingNetworkService: EventLoggingNetworkService {
    var shouldSucceed = true

    override func uploadFile(request: URLRequest, fileURL: URL, completion: @escaping EventLoggingNetworkService.ResultCallback) {
        shouldSucceed ? completion(.success(Data())) : completion(.failure(MockError.generic))
    }
}

class MockEventLoggingUploadQueue: EventLoggingUploadQueue {

    typealias LogFileCallback = (LogFile) -> ()

    var queue = [LogFile]()

    var addCallback: LogFileCallback?
    override func add(_ log: LogFile) {
        self.addCallback?(log)
        self.queue.append(log)
    }

    var removeCallback: LogFileCallback?
    override func remove(_ log: LogFile) {
        self.removeCallback?(log)
        self.queue.removeAll(where: { $0.uuid == log.uuid })
    }

    override var first: LogFile? {
        return self.queue.first
    }
}
