import Foundation

@available(iOS 14.0, OSX 11.0, *)
public class TracksManager {

    public let tracksService: TracksService

    public let tracksEventStorage: TracksEventStorage

    public let userDataSource: TracksUserProvider

    private let contextManager = TracksContextManager()

    public init(userDataSource: TracksUserProvider) throws {
        self.tracksService = TracksService(contextManager: contextManager)
        self.tracksService.remoteCallsEnabled = false

        self.userDataSource = userDataSource

        self.tracksEventStorage = try TracksEventStorage(tracksContextManager: contextManager)
    }
}
