import SwiftUI
import AutomatticTracks

class RootViewController: NSHostingController<RootUIView> {

    private let settings = Settings()

    init() {

        let logFileStorage = LogFileStorage(
            url: EventLoggingDefaults.defaultQueueStoragePath,
            dataProvider: EventLoggingDataProvider(settings: settings)
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
            dataProvider: EventLoggingDataProvider(settings: settings)
        )

        let tracksManager = try! TracksManager(userDataSource: Settings())

        let rootView = RootUIView(
            tracksManager: tracksManager,
            logFileStorage: logFileStorage
        )

        super.init(coder: aDecoder, rootView: rootView)
    }
}
