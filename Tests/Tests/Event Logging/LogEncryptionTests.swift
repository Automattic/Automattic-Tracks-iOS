import XCTest
import Sodium

#if SWIFT_PACKAGE
@testable import AutomatticRemoteLogging
@testable import AutomatticEncryptedLogs
#else
@testable import AutomatticTracks
#endif


class LogEncryptionTests: XCTestCase {

    private var keyPair: Box.KeyPair!
    private var sodium: Sodium!

    override func setUp() {
        super.setUp()
        self.sodium = Sodium()
        self.keyPair = sodium.box.keyPair()!
    }

    override func tearDown() {
        keyPair = nil
        sodium = nil

        super.tearDown()
    }

    func testSecretEncryptor() {
        let secret = String.randomString(length: 64).bytes
        let encryptedSecret = try! LogEncryptor(withPublicKey: keyPair.publicKey)
            .encryptSecretWithSodium(secret: secret)

        let decryptedSecret = sodium.box.open(anonymousCipherText: encryptedSecret, recipientPublicKey: keyPair.publicKey, recipientSecretKey: keyPair.secretKey)

        XCTAssertEqual(secret, decryptedSecret)
    }

    func testEndToEndEncryption() {
        let logLength = Int.random(in: 0...Int(Int16.max))
        let log = String.randomString(length: logLength)

        let encryptor = LogEncryptor(withPublicKey: keyPair.publicKey)
        let encryptedLogURL = try! encryptor.encryptLog(LogFile(containing: log))
        let decryptedLogURL = try! LogDecryptor(withKeyPair: keyPair).decrypt(file: encryptedLogURL)

        XCTAssertEqual(try! String(contentsOf: decryptedLogURL), log)
    }

    func testLogFormatMatchesV1() throws {
        let encryptor = LogEncryptor(withPublicKey: keyPair.publicKey)
        let encryptedLogURL = try encryptor.encryptLog(LogFile.containingRandomString())
        let encryptedMessage = try EncryptedMessage.fromURL(encryptedLogURL)

        XCTAssertEqual(encryptedMessage.keyedWith, "v1", "`keyedWith` must ALWAYS be v1 in this version of the file format")
        XCTAssertNotNil(UUID(uuidString: encryptedMessage.uuid), "The UUID must be valid")
        XCTAssertEqual(encryptedMessage.header.count, 32, "The header should be 32 bytes long")
        XCTAssertEqual(encryptedMessage.encryptedKey.count, 108, "The encrypted key should be 108 bytes long")
        XCTAssert(encryptedMessage.messages.count > 0, "There should be at least one message")
    }
}

private class LogDecryptor {

    private let keyPair: Box.KeyPair
    private let sodium = Sodium()

    init(withKeyPair keyPair: Box.KeyPair) {
        self.keyPair = keyPair
    }

    func decrypt(file: URL) throws -> URL {

        let encryptedMessage = try EncryptedMessage.fromURL(file)
        let decryptedKey = decryptMessageKey(encryptedMessage.encryptedKey.base64Decoded)
        let header = encryptedMessage.header.base64Decoded
        let stream = sodium.secretStream.xchacha20poly1305.initPull(secretKey: decryptedKey, header: header)!

        let newTempFile = FileManager.default.createTempFile(named: "decrypted-file-" + UUID().uuidString, containing: "")
        let fileHandle = try FileHandle(forWritingTo: newTempFile)
        defer {
            fileHandle.closeFile()
        }

        encryptedMessage.messages.forEach {
            let messageBytes = $0.base64Decoded
            let (message, _) = stream.pull(cipherText: messageBytes)!

            fileHandle.write(Data(message))
        }

        return newTempFile
    }

    private func decryptMessageKey(_ secret: Bytes) -> Bytes {
        return sodium.box.open(anonymousCipherText: secret,
                                 recipientPublicKey: keyPair.publicKey,
                                 recipientSecretKey: keyPair.secretKey)!
    }
}
