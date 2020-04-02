import Foundation
import CocoaLumberjack
import Sodium

class EventLoggingUploadManager {

    private enum Constants {
        static let uuidHeaderKey = "log-uuid"
        static let uploadHttpMethod = "POST"
    }

    private let dataSource: EventLoggingDataSource
    private let delegate: EventLoggingDelegate
    private let networkService: EventLoggingNetworkService
    private let fileManager: FileManager

    typealias LogUploadCallback = (Result<Void, Error>) -> Void

    init(dataSource: EventLoggingDataSource,
         delegate: EventLoggingDelegate,
         networkService: EventLoggingNetworkService = EventLoggingNetworkService(),
         fileManager: FileManager = FileManager.default
    ) {
        self.dataSource = dataSource
        self.delegate = delegate
        self.networkService = networkService
        self.fileManager = fileManager
    }

    func upload(_ log: LogFile, then callback: @escaping LogUploadCallback) {
        guard delegate.shouldUploadLogFiles else {
            delegate.uploadCancelledByDelegate(log)
            callback(.failure(EventLoggingFileUploadError.cancelledByDelegate))
            return
        }

        guard let fileContents = fileManager.contents(atUrl: log.url) else {
            let error = EventLoggingFileUploadError.fileMissing
            delegate.uploadFailed(withError: error, forLog: log)
            callback(.failure(error))
            return
        }

        var request = URLRequest(url: dataSource.logUploadURL)
        request.addValue(log.uuid, forHTTPHeaderField: Constants.uuidHeaderKey)
        request.httpMethod = Constants.uploadHttpMethod
        request.httpBody = fileContents

        delegate.didStartUploadingLog(log)

        networkService.uploadFile(request: request, fileURL: log.url) { result in
            switch result {
                case .success:
                    callback(.success(()))
                    /// fire after the callback so the hosting app can act on the result of the callback (such as removing the log from the queue)
                    self.delegate.didFinishUploadingLog(log)
                case .failure(let error):
                    callback(.failure(error))
                    /// fire after the callback so the hosting app can act on any state changes caused by the callback
                    self.delegate.uploadFailed(withError: error, forLog: log)
            }
        }
    }
}
