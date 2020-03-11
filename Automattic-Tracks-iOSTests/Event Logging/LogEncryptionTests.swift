import XCTest
import Sodium
@testable import AutomatticTracks

class LogEncryptionTests: XCTestCase {

    private var keyPair: Box.KeyPair!
    private var log: String!

    override func setUp() {
        // Put setup code here. This method is called before the invocation of each test method in the class.
        self.keyPair = Sodium().box.keyPair()!

        let logLength = Int.random(in: 0...Int(Int16.max))
        self.log = String.randomString(length: logLength)
    }

    func testSecretEncryptor() {
        let secret = String.randomString(length: 64).bytes
        let encryptedSecret = try! LogEncryptor(withPublicKey: keyPair.publicKey)
            .encryptSecretWithSodium(secret: secret)

        let decryptedSecret = Sodium().box.open(anonymousCipherText: encryptedSecret, recipientPublicKey: keyPair.publicKey, recipientSecretKey: keyPair.secretKey)

        XCTAssertEqual(secret, decryptedSecret)
    }

    func testEndToEndEncryption() {
        let encryptor = LogEncryptor(withPublicKey: keyPair.publicKey)
        let encryptedLogURL = try! encryptor.encryptLog(MockLogFile(string: self.log))
        let decryptedLogURL = try! LogDecryptor(withKeyPair: keyPair).decrypt(file: encryptedLogURL)

        XCTAssertEqual(try! String(contentsOf: decryptedLogURL), log)
    }

    func testLogFormatMatchesV1() throws {
        let encryptor = LogEncryptor(withPublicKey: keyPair.publicKey)
        let encryptedLogURL = try encryptor.encryptLog(MockLogFile(string: self.log))
        let encryptedMessage = try EncryptedMessage.fromURL(encryptedLogURL)

        XCTAssertEqual(encryptedMessage.keyedWith, "v1")
        XCTAssertNotNil(UUID(uuidString: encryptedMessage.uuid), "The UUID must be valid")
        XCTAssertEqual(encryptedMessage.header.count, 32, "The header should be 32 bytes long")
        XCTAssertEqual(encryptedMessage.encryptedKey.count, 108, "The encrypted key should be 108 bytes long")
        XCTAssert(encryptedMessage.messages.count > 0, "There should be at least one message")
    }
}

private class LogDecryptor {

    private let keyPair: Box.KeyPair

    init(withKeyPair keyPair: Box.KeyPair) {
        self.keyPair = keyPair
    }

    func decrypt(file: URL) throws -> URL {

        let encryptedMessage = try EncryptedMessage.fromURL(file)
        let decryptedKey = decryptMessageKey(encryptedMessage.encryptedKey.base64Decoded)
        let header = encryptedMessage.header.base64Decoded
        let stream = Sodium().secretStream.xchacha20poly1305.initPull(secretKey: decryptedKey, header: header)!

        let newTempFile = FileManager.default.createTempFile(named: "decrypted-file-" + UUID().uuidString, containing: "")
        let fileHandle = try FileHandle(forWritingTo: newTempFile)
        var string = ""

        encryptedMessage.messages.forEach {
            let messageBytes = $0.base64Decoded
            let (message, _) = stream.pull(cipherText: messageBytes)!

            fileHandle.write(Data(message))
            string.append(String(bytes: message, encoding: .utf8)!)
        }

        fileHandle.closeFile()

        return newTempFile
    }

    private func decryptMessageKey(_ secret: Bytes) -> Bytes {
        return Sodium().box.open(anonymousCipherText: secret,
                                 recipientPublicKey: keyPair.publicKey,
                                 recipientSecretKey: keyPair.secretKey)!
    }
}
