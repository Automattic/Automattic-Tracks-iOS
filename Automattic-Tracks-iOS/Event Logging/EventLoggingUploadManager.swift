import Foundation
import CocoaLumberjack
import Sodium

class EventLoggingUploadManager {

    private struct Constants {
        static let uuidHeaderKey = "log-uuid"
        static let uploadHttpMethod = "POST"
    }

    internal var networkService = EventLoggingNetworkService()

    internal var dataSource: EventLoggingDataSource!
    internal var delegate: EventLoggingDelegate!

    typealias LogUploadCallback = (Result<Void, Error>) -> Void

    func upload(_ log: LogFile, then callback: @escaping LogUploadCallback) {

        precondition(delegate != nil , "You must set the Event Logging Delegate prior to attempting an upload")
        precondition(dataSource != nil , "You must set the Event Logging Data Source prior to attempting an upload")

        guard delegate.shouldUploadLogFiles else {
            delegate?.uploadCancelledByDelegate(log)
            return
        }

        guard let fileContents = FileManager.default.contents(atUrl: log.url) else {
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
