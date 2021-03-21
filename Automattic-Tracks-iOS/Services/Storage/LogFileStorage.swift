import Combine

@available(iOS 13.0, OSX 10.15, *)
public class LogFileStorage: ObservableObject {

    @Published
    public var logFiles: [LogFile]

    private let monitor: DirectoryMonitorProtocol

    private let eventLogging: EventLogging

    private var cancellable: AnyCancellable?

    private let logFileEmitter = EventLoggingEmitter()

    public convenience init(url: URL, dataProvider: EventLoggingDataSource & EventLoggingDelegate) {
        let eventLogging = EventLogging(dataSource: dataProvider, delegate: dataProvider)
        self.init(url: url, eventLogging: eventLogging)
    }

    public convenience init(url: URL, dataSource: EventLoggingDataSource, delegate: EventLoggingDelegate) {
        let eventLogging = EventLogging(dataSource: dataSource, delegate: delegate)
        self.init(url: url, eventLogging: eventLogging)
    }

    init(url: URL, eventLogging: EventLogging, monitor: DirectoryMonitorProtocol? = nil) {

        /// If the specified URL doesn't exist – create it
        if !FileManager.default.directoryExistsAtURL(url) {
            try! FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        }

        let monitor = monitor ?? DirectoryMonitor(url: url)

        self.eventLogging = eventLogging
        self.monitor = monitor
        self.logFiles = monitor.contents.map { LogFile(url: $0, uuid: $0.lastPathComponent) }.sorted()
        self.cancellable = self.monitor.files.eraseToAnyPublisher()
            .map(self.transform)
            .receive(on: DispatchQueue.main)
            .sink(receiveValue: self.updateLogFilePublisher)
    }

    deinit {
        cancellable?.cancel()
    }

    private func transform(_ urls: [URL]) -> [LogFile] {
        return urls
            .map { LogFile(url: $0, uuid: $0.lastPathComponent) }
            .sorted()
    }

    /// These methods aren't storage related – once we can make `EventLogging` an `ObservableObject`,
    /// it should be injected into the relevant places and these should be removed
    private func updateLogFilePublisher(_ logFiles: [LogFile]) {
        self.objectWillChange.send()
        self.logFiles = logFiles
    }

    public func enqueueLogFileForUpload(_ logFile: LogFile) throws {
        try eventLogging.enqueueLogForUpload(log: logFile)
    }

    private var isDoneCancellable: AnyCancellable?

    public func uploadQueuedLogFiles() {
        eventLogging.shouldAutomaticallyUploadLogFiles = true
        eventLogging.uploadNextLogFileIfNeeded()

        /// Automatically pause the queue when upload is complete
        isDoneCancellable = logFileEmitter.isDonePublisher.sink { _ in
            self.eventLogging.shouldAutomaticallyUploadLogFiles = false
        }
    }
}
