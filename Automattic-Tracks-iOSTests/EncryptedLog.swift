import Foundation

struct EncryptedMessage: Codable {
    let keyedWith: String
    let encryptedKey: String
    let header: String
    let uuid: String
    let messages: [String]

    static func fromURL(_ url: URL) throws -> EncryptedMessage {
       return try JSONDecoder().decode(EncryptedMessage.self, from: try Data(contentsOf: url))
    }
}
