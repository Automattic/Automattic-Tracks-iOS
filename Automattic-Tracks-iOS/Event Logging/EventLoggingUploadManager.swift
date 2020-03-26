import Foundation
import CocoaLumberjack
import Sodium

class EventLoggingUploadManager {

    private enum Constants {
        static let uuidHeaderKey = "log-uuid"
        static let uploadHttpMethod = "POST"
    }

    var dataSource: EventLoggingDataSource
    var delegate: EventLoggingDelegate
    var networkService: EventLoggingNetworkService = EventLoggingNetworkService()
    var fileManager: FileManager = FileManager.default

    typealias LogUploadCallback = (Result<Void, Error>) -> Void

    init(dataSource: EventLoggingDataSource, delegate: EventLoggingDelegate) {
        self.dataSource = dataSource
        self.delegate = delegate
    }

    func upload(_ log: LogFile, then callback: @escaping LogUploadCallback) {
        guard delegate.shouldUploadLogFiles else {
            delegate.uploadCancelledByDelegate(log)
            return
        }

        guard let fileContents = fileManager.contents(atUrl: log.url) else {
            delegate.uploadFailed(withError: EventLoggingFileUploadError.fileMissing, forLog: log)
            return
        }

        var request = URLRequest(url: dataSource.logUploadURL)
        request.addValue(log.uuid, forHTTPHeaderField: Constants.uuidHeaderKey)
        request.httpMethod = Constants.uploadHttpMethod
        request.httpBody = fileContents

        delegate.didStartUploadingLog(log)

        networkService.uploadFile(request: request, fileURL: log.url) { result in
            switch(result) {
                case .success:
                    self.delegate.didFinishUploadingLog(log)
                    callback(.success(()))
                case .failure(let error):
                    self.delegate.uploadFailed(withError: error, forLog: log)
                    callback(.failure(error))
            }
        }
    }
}
