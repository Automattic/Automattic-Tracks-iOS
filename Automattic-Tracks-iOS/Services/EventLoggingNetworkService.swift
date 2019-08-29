import Foundation

typealias NetworkResultCallback = (Result<Data?, Error>) -> Void

open class EventLoggingNetworkService {

    func uploadFile(request: URLRequest, fileURL: URL, completion: @escaping NetworkResultCallback) {
        URLSession.shared
            .uploadTask(with: request, fromFile: fileURL, completionHandler: { data, response, error in

            if let error = error {
                completion(.failure(error))
                return
            }

            /// The `response` should *always* be an HTTPURLResponse, but we'll be defensive anyway
            guard let statusCode = (response as? HTTPURLResponse)?.statusCode else {
                completion(.success(data))
                return
            }

            /// Generate a reasonable error message based on the HTTP status
            if !(200 ... 299).contains(statusCode) {
                let errorMessage = HTTPURLResponse.localizedString(forStatusCode: statusCode)
                completion(.failure(UploadError.httpError(errorMessage)))
                return
            }

            completion(.success(data))
        }).resume()
    }
}
