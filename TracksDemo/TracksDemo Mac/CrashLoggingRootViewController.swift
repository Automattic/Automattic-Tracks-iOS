import SwiftUI
import AutomatticTracks

class CrashLoggingRootViewController: NSHostingController<RootUIView> {

    private let eventLoggingDataProvider = EventLoggingDataProvider(settings: Settings())

    private let crashLogging = try! CrashLogging(dataProvider: CrashLoggingDataSource()).start()

    private let tracksManager = try! TracksManager(userDataSource: Settings())

    init() {

        let logFileStorage = LogFileStorage(
            url: EventLoggingDefaults.defaultQueueStoragePath,
            dataSource: eventLoggingDataProvider,
            delegate: eventLoggingDataProvider
        )

        let rootView = RootUIView(
            tracksManager: tracksManager,
            crashLogging: crashLogging,
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

        let rootView = RootUIView(
            tracksManager: tracksManager,
            crashLogging: crashLogging,
            logFileStorage: logFileStorage
        )

        super.init(coder: aDecoder, rootView: rootView)
    }
}
