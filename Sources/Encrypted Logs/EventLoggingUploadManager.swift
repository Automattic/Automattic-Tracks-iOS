import Foundation
import Sodium

class EventLoggingUploadManager {

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

        guard fileManager.fileExistsAtURL(log.url) else {
            let error = EventLoggingFileUploadError.fileMissing
            delegate.uploadFailed(withError: error, forLog: log)
            callback(.failure(error))
            return
        }

        let request = createRequest(
            url: dataSource.logUploadURL,
            uuid: log.uuid, authenticationToken:
            dataSource.loggingAuthenticationToken
        )

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

    func createRequest(url: URL, uuid: String, authenticationToken: String) -> URLRequest {
        var request = URLRequest(url: url)
        request.addValue(uuid, forHTTPHeaderField: "log-uuid")
        request.addValue(authenticationToken, forHTTPHeaderField: "Authorization")
        request.httpMethod = "POST"

        return request
    }
}
