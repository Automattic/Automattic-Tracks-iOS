import Foundation
import Combine

@available(OSX 10.15, iOS 13.0, *)
public class EventLoggingPublisher: ObservableObject {

    public enum State {
        case uploading
        case paused(until: Date)
        case done
    }

    @Published public var logFiles: [LogFile] = []
    @Published public var state: State = .uploading

    func set(logFiles: [LogFile]) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.logFiles = logFiles
        }
    }

    func set(state: State) {
        DispatchQueue.main.async {
            self.objectWillChange.send()
            self.state = state
        }
    }
}
