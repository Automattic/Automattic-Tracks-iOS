import Foundation

public typealias FileAttributes = [FileAttributeKey: Any]

public extension FileAttributes {
    var fileCreationDate: Date? {
        return self[FileAttributeKey.creationDate] as? Date
    }
}

public extension FileManager {

    var documentsDirectory: URL {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        return URL(fileURLWithPath: documentsDirectory, isDirectory: true)
    }

    func contentsOfDirectory(at url: URL) throws -> [URL] {
        return try self.contentsOfDirectory(atPath: url.path).map { url.appendingPathComponent($0) }
    }

    func contents(atUrl url: URL) -> Data? {
        return self.contents(atPath: url.path)
    }

    func fileExistsAtURL(_ url: URL) -> Bool {
        return self.fileExists(atPath: url.path)
    }

    func directoryExistsAtURL(_ url: URL) -> Bool {
        var isDir: ObjCBool = false
        let exists = self.fileExists(atPath: url.path, isDirectory: &isDir)
        return exists && isDir.boolValue
    }

    func attributesOfItem(at url: URL) throws -> FileAttributes {
        return try self.attributesOfItem(atPath: url.path)
    }

    func setAttributesOfItem(attributes: FileAttributes, at url: URL) throws {
        return try self.setAttributes(attributes, ofItemAtPath: url.path)
    }
}
