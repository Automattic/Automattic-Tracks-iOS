import Combine

@available(iOS 13.0, OSX 10.15, *)
protocol DirectoryMonitorProtocol {
    var files: PassthroughSubject<[URL], Never> { get }
}

@available(iOS 13.0, OSX 10.15, *)
public class DirectoryMonitor: ObservableObject, DirectoryMonitorProtocol {

    public var files = PassthroughSubject<[URL], Never>()

    private let url: URL

    private let internalQueue = DispatchQueue(label: "directory-monitor-internal-queue")
    private let directoryMonitorSource: DispatchSourceFileSystemObject

    private let fileDescriptor: Int32

    init(url: URL) {
        self.url = url

        fileDescriptor = open(url.path, O_EVTONLY)

        directoryMonitorSource = DispatchSource.makeFileSystemObjectSource(fileDescriptor: fileDescriptor, eventMask: [.write, .delete], queue: internalQueue)
        directoryMonitorSource.setEventHandler(handler: self.directoryDidChange)
        directoryMonitorSource.setCancelHandler(handler: self.cancelDirectoryMonitor)
        directoryMonitorSource.resume()
    }

    deinit {
        directoryMonitorSource.cancel()
    }

    private func directoryDidChange() {
        let files = FileManager.default.subpaths(atPath: url.path)?.compactMap { URL(fileURLWithPath: $0) } ?? []
        self.files.send(files)
    }

    private func cancelDirectoryMonitor() {
        close(fileDescriptor)
    }
}
