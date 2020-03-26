import Foundation
import OHHTTPStubs

func stubResponse(domain: String, status: String, statusCode: Int32 = 200) {
    stub(condition: isHost(domain)) { _ in
        let stubData = "{status: \"\(status)\"}".data(using: .utf8)!
        return HTTPStubsResponse(data: stubData, statusCode: statusCode, headers: nil)
    }
}
