import Foundation

class EventLoggingNetworkService {

    typealias ResultCallback = (Result<Data?, Error>) -> Void

    private let urlSession: URLSession

    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }

    func uploadFile(request: URLRequest, fileURL: URL, completion: @escaping ResultCallback) {
        urlSession.uploadTask(with: request, fromFile: fileURL, completionHandler: { data, response, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            /// The `response` should *always* be an HTTPURLResponse.
            /// Fail fast by force-unwrapping – this will cause a crash and will bring the issue to our attention if something has changed.
            let statusCode = (response as! HTTPURLResponse).statusCode

            /// Generate a reasonable error message based on the HTTP status
            if !(200 ... 299).contains(statusCode) {
                let errorMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
                completion(.failure(EventLoggingFileUploadError.httpError(errorMessage)))
                return
            }

            completion(.success(data))
        }).resume()
    }
}
