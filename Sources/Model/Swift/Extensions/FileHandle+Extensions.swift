import Foundation

extension FileHandle {
    /// A chunked version of the `readDataToEndOfFile` method
    public func readChunkedDataToEndOfFile(next: (Data) throws -> Void, chunkSize: Int = 4096) throws {
        var shouldContinue = true
        repeat {
            let data = self.readData(ofLength: chunkSize)
            try next(data)
            shouldContinue = data.count == chunkSize
        } while shouldContinue
    }
}
