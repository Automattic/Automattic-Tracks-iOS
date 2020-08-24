import Foundation
import OHHTTPStubs

func stubResponse(domain: String, status: String, statusCode: Int32 = 200) {
    stub(condition: isHost(domain)) { _ in
        let stubData = "{status: \"\(status)\"}".data(using: .utf8)!
        return HTTPStubsResponse(data: stubData, statusCode: statusCode, headers: nil)
    }
}

func stubErrorResponse(domain: String, error: String, message: String, statusCode: Int32 = 400) {
    stub(condition: isHost(domain)) { _ in
        let stubData = "{\"error\":\"\(error)\",\"message\":\"\(message)\"}".data(using: .utf8)!
        return HTTPStubsResponse(data: stubData, statusCode: statusCode, headers: nil)
    }
}
