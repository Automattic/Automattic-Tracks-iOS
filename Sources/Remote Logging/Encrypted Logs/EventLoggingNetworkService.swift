import Foundation

#if SWIFT_PACKAGE
import AutomatticTracksModel
#endif

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

            if !(200 ... 299).contains(statusCode) {
                /// Use the server-provided error messaging, if possible
                if let data = data, let error = self.decodeError(data: data) {
                    completion(.failure(EventLoggingFileUploadError.httpError(error.error, error.message, statusCode)))
                }
                /// Fallback to a reasonable error message based on the HTTP status and response body
                else {
                    let errorMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
                    let errorBody = String(data: data ?? Data(), encoding: .utf8) ?? ""
                    completion(.failure(EventLoggingFileUploadError.httpError(errorMessage, errorBody, statusCode)))
                }

                return
            }

            completion(.success(data))
        }).resume()
    }

    // MARK: - API Errors

    /// An object representing the associated WordPress.com API error
    struct EventLoggingNetworkServiceError: Codable {
        let error: String
        let message: String
    }

    private func decodeError(data: Data) -> EventLoggingNetworkServiceError? {
        return try? JSONDecoder().decode(EventLoggingNetworkServiceError.self, from: data)
    }
}
