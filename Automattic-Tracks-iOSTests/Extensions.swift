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
