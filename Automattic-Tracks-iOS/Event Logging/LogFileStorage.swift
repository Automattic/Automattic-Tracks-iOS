import Combine

@available(iOS 13.0, OSX 10.15, *)
public class LogFileStorage: ObservableObject {

    @Published
    public var logFiles = [LogFile]()

    private let monitor: DirectoryMonitorProtocol

    private var cancellable: AnyCancellable?

    init(url: URL, monitor : DirectoryMonitorProtocol? = nil) {
        self.monitor = monitor ?? DirectoryMonitor(url: url)
        self.cancellable = self.monitor.files.eraseToAnyPublisher()
            .map(self.transform)
            .sink(receiveValue: self.updateLogFilePublisher)
    }

    deinit {
        cancellable?.cancel()
    }

    private func transform(_ urls: [URL]) -> [LogFile] {
        urls.map { LogFile(url: $0, uuid: $0.lastPathComponent) }
    }

    private func updateLogFilePublisher(_ logFiles: [LogFile]) {
        self.logFiles = logFiles
    }
}
