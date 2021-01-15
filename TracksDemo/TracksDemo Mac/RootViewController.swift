import SwiftUI
import AutomatticTracks

class RootViewController: NSHostingController<RootUIView> {

    private let eventLoggingDataProvider = EventLoggingDataProvider()

    init() {
        let logFileStorage = LogFileStorage(
            url: EventLoggingDefaults.defaultQueueStoragePath,
            dataSource: eventLoggingDataProvider,
            delegate: eventLoggingDataProvider
        )

        let tracksManager = try! TracksManager(userDataSource: Settings())

        let rootView = RootUIView(
            tracksManager: tracksManager,
            logFileStorage: logFileStorage
        )

        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        let logFileStorage = LogFileStorage(
            url: EventLoggingDefaults.defaultQueueStoragePath,
            dataSource: eventLoggingDataProvider,
            delegate: eventLoggingDataProvider
        )

        let tracksManager = try! TracksManager(userDataSource: Settings())

        let rootView = RootUIView(
            tracksManager: tracksManager,
            logFileStorage: logFileStorage
        )

        super.init(coder: aDecoder, rootView: rootView)
    }
}
