import Foundation
import Sodium
import XCTest

extension String {
    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map { _ in letters.randomElement()! })
    }

    var base64Decoded: Bytes {
        return Data(base64Encoded: self)!.bytes
    }
}

extension Data {
    var bytes: Bytes {
        return Bytes(self)
    }
}

extension FileManager {

    func createTempFile(named name: String, containing contents: String?) -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        self.createFile(atPath: fileURL.path, contents: contents?.data(using: .utf8), attributes: nil)
        return fileURL
    }
}

extension XCTestCase {

    /// Wait the specificed time for an expectation to be fulfilled. Takes a block that receives the expecatation, so this is useful for testing async code.
    ///
    /// - Parameters:
    ///     - timeout: How long to wait for the expectation to be fulfilled.
    ///     - block: A developer-provided unit of computation that receives the expectation and returns a value that will become the return value of this method.
    ///     - expectation: An unfulfilled XCTestExpectation.
    func waitForExpectation(timeout: TimeInterval = 60.0, block: (_ expectation: XCTestExpectation) -> ()) {
        let exp = XCTestExpectation()
        block(exp)
        wait(for: [exp], timeout: timeout)
    }

    /// Wait the specified time for an expectation to be fulfilled. Takes a block that receives the expectation and returns a specified type
    /// so this is useful for testing async code when you need to examine a result following the expectation being
    ///
    /// - Parameters:
    ///     - timeout: How long to wait for the expectation to be fulfilled.
    ///     - block: A developer-provided unit of computation that receives the expectation and returns a value that will become the return value of this method.
    ///     - expectation: An unfulfilled XCTestExpectation.
    /// - Returns: The value provided by `block`, which can specify its own return type
    func waitForExpectation<T>(timeout: TimeInterval = 60.0, block: (_ expectation: XCTestExpectation) -> (T)) -> T {
        let exp = XCTestExpectation()
        let result = block(exp)
        wait(for: [exp], timeout: timeout)

        return result
    }

    /// Wait the specificed time for an expectation to be fulfilled. Takes a block that can throw, so this is useful for testing async code
    /// that might also `throw`.
    ///
    /// - Parameters:
    ///     - timeout: How long to wait for the expectation to be fulfilled.
    ///     - block: A developer-provided unit of computation that receives the expectation and performs a throwing operation.
    ///     - expectation: An unfulfilled XCTestExpectation.
    func waitForExpectation(timeout: TimeInterval = 60.0, block: (_ expectation: XCTestExpectation) throws -> ()) rethrows {
        let exp = XCTestExpectation()
        try block(exp)
        wait(for: [exp], timeout: timeout)
    }
}
