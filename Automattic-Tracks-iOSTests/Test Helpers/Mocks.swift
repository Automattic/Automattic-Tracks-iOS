import Foundation
import Sodium
@testable import AutomatticTracks

typealias LogFileCallback = (LogFile) -> ()
typealias ErrorWithLogFileCallback = (Error, LogFile) -> ()

enum MockError: Error {
    case generic
}

class MockEventLoggingDataSource: EventLoggingDataSource {
    
    private let _loggingEncryptionKey: String
    private let _logUploadURL: URL
    
    required init (loggingEncryptionKey: String, logUploadURL: URL) {
        _loggingEncryptionKey = loggingEncryptionKey
        _logUploadURL = logUploadURL
    }
    
    var loggingEncryptionKey: String {
        return _loggingEncryptionKey
    }
    
    var logUploadURL: URL {
        return _logUploadURL
    }

    var previousSessionLogPath: URL? {
        return nil
    }

    static func withEncryptionKeys() -> Self {
        let keyPair = Sodium().box.keyPair()!
        let encryptionKey = Data(keyPair.publicKey).base64EncodedString()
        return Self(loggingEncryptionKey: encryptionKey, logUploadURL: URL(string: "example.com")!)
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
