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

    var shouldUploadLogFiles: Bool = true

    private var _didStartUploadingTriggered = false
    private var _didFinishUploadingTriggered = false
    private var _uploadFailedTriggered = false
    private var _uploadCancelledByDelegateTriggered = false

    var didStartUploadingTriggered: Bool {
        return _didStartUploadingTriggered
    }

    var didFinishUploadingTriggered: Bool {
        return _didFinishUploadingTriggered
    }

    var uploadFailedTriggered: Bool {
        return _uploadFailedTriggered
    }

    var uploadCancelledByDelegateTriggered: Bool {
        return _uploadCancelledByDelegateTriggered
    }

    var didStartUploadingCallback: LogFileCallback?
    var didFinishUploadingCallback: LogFileCallback?
    var uploadCancelledByDelegateCallback: LogFileCallback?
    var uploadFailedCallback: ErrorWithLogFileCallback?

    func didStartUploadingLog(_ log: LogFile) {
        _didStartUploadingTriggered = true
        didStartUploadingCallback?(log)
    }


    func didFinishUploadingLog(_ log: LogFile) {
        _didFinishUploadingTriggered = true
        didFinishUploadingCallback?(log)
    }

    func uploadCancelledByDelegate(_ log: LogFile) {
        _uploadCancelledByDelegateTriggered = true
        uploadCancelledByDelegateCallback?(log)
    }

    func uploadFailed(withError error: Error, forLog log: LogFile) {
        _uploadFailedTriggered = true
        uploadFailedCallback?(error, log)
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
