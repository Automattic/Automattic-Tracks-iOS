import Foundation

extension FileManager {
    
    func createTempFile(named name: String, containing contents: String?) -> URL {
        let fileURL = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(name)
        self.createFile(atPath: fileURL.path, contents: contents?.data(using: .utf8), attributes: nil)
        return fileURL
    }
}
