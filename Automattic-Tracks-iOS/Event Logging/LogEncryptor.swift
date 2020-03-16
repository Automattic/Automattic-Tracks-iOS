import Foundation
import Sodium

class LogEncryptor {

    private let publicKey: Bytes

    enum LogEncryptorError: Error {
        case unableToReadFile
        case unableToEncryptFile
        case logSecretTooLong
        case unableToWriteFile
    }

    init(withPublicKey key: Bytes) {
        self.publicKey = key
    }

    func encryptLog(_ log: LogFile) throws -> URL {

        /// Set up our output path
        let uniqueSegment = UUID().uuidString + "-" + log.url.lastPathComponent
        let outputURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(uniqueSegment)
        assert(outputURL.path != log.url.path, "The output file path must be unique")

        /// Do the encrypted stream setup
        let sodium = Sodium()
        let secretkey = sodium.secretStream.xchacha20poly1305.key()
        let encryptedKey = try encryptSecretWithSodium(secret: secretkey)
        let stream_enc = sodium.secretStream.xchacha20poly1305.initPush(secretKey: secretkey)!
        let header = stream_enc.header()

        /// Prep our file handles
        try initializeOutputFile(at: outputURL)
        let inputFileHandle = try FileHandle(forReadingFrom: log.url)
        let outputFileHandle = try FileHandle(forWritingTo: outputURL)

        defer {
            inputFileHandle.closeFile()
            outputFileHandle.closeFile()
        }

        /// Write JSON Preamble
        outputFileHandle.write("""
        {
            "keyedWith": "v1",
            "encryptedKey": "\(Data(encryptedKey).base64EncodedString())",
            "header": "\(Data(header).base64EncodedString())",
            "uuid": "\(log.uuid)",
            "messages": [\n
        """.data(using: .utf8)!)

        /// Use the `next:` label because of https://bugs.swift.org/browse/SR-1582
        try inputFileHandle.readChunkedDataToEndOfFile(next: { (data) in
            guard let message = stream_enc.push(message: Bytes(data)) else {           // encrypt the data
                throw LogEncryptorError.unableToEncryptFile
            }

            try writeTo(outputFileHandle, message: message)                            // write the data
        })

        /// Write the end of the encryption stream
        let final = stream_enc.push(message: "".bytes, tag: .FINAL)!                    // This should never fail
        try writeTo(outputFileHandle, message: final, willHaveMore: false)

        /// Write out the end of the JSON file
        outputFileHandle.write("""
            ]
        }
        """.data(using: .utf8)!)

        return outputURL
    }

    internal func encryptSecretWithSodium(secret: Bytes) throws -> Bytes {
        return Sodium().box.seal(message: secret, recipientPublicKey: publicKey)!
    }

    private func initializeOutputFile(at outputURL: URL) throws {

        if FileManager.default.fileExists(atPath: outputURL.path) {
            try FileManager.default.removeItem(at: outputURL)
        }

        guard FileManager.default.createFile(atPath: outputURL.path, contents: nil, attributes: nil) else {
            throw LogEncryptorError.unableToWriteFile
        }
    }

    private func writeTo(_ fileHandle: FileHandle, message: Bytes, willHaveMore: Bool = true) throws {

        fileHandle.write("        \"".data(using: .utf8)!)
        fileHandle.write(Data(message).base64EncodedData())

        /// There should be a comma if there will be another line after this one
        let closingQuote = willHaveMore ? "\",\n" : "\"\n"
        fileHandle.write(closingQuote.data(using: .utf8)!)
    }
}
