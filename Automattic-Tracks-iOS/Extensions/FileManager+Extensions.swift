import Foundation

typealias FileAttributes = [FileAttributeKey: Any]

extension FileAttributes {
    var creationDate: Date? {
        get {
            return self[FileAttributeKey.creationDate] as? Date
        }
        set {
            self[FileAttributeKey.creationDate] = newValue
        }
    }

    var modificationDate: Date? {
        get {
            return self[FileAttributeKey.modificationDate] as? Date
        }
        set {
            self[FileAttributeKey.modificationDate] = newValue
        }
    }
}

extension FileManager {

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

    func setCreationDate(forItemAt url: URL, to date: Date = Date()) throws {
        var attributes = try self.attributesOfItem(at: url)

        /// The modification date can't be before the creation date, so update both in this case
        if attributes.modificationDate != nil && attributes.modificationDate! < date {
            attributes.modificationDate = date
        }

        attributes.creationDate = date

        try setAttributesOfItem(attributes: attributes, at: url)
    }
}
