import Foundation
import Sodium

extension String {
    static func randomString(length: Int) -> String {
      let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
      return String((0..<length).map{ _ in letters.randomElement()! })
    }

    var base64Decoded: Bytes {
        return Data(base64Encoded: self)!.bytes
    }
}

extension Data {
    var bytes: Bytes {
        return [UInt8](self)
    }
}

extension FileManager {

    func createTempFile(named name: String, containing contents: String?) -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        self.createFile(atPath: fileURL.path, contents: contents?.data(using: .utf8), attributes: nil)
        return fileURL
    }
}
