import UIKit
import SwiftUI

import AutomatticTracks

class RootViewController: UIHostingController<RootUIView> {

    private let eventLoggingDataProvider = EventLoggingDataProvider()

    init() {
        let logFileStorage = LogFileStorage(
            url: EventLoggingDefaults.defaultQueueStoragePath,
            dataSource: eventLoggingDataProvider,
            delegate: eventLoggingDataProvider
        )

        super.init(rootView: RootUIView(tracksManager: try! TracksManager(userDataSource: Settings()), logFileStorage: logFileStorage))
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        let logFileStorage = LogFileStorage(
            url: EventLoggingDefaults.defaultQueueStoragePath,
            dataSource: eventLoggingDataProvider,
            delegate: eventLoggingDataProvider
        )

        super.init(coder: aDecoder, rootView: RootUIView(tracksManager: try! TracksManager(userDataSource: Settings()), logFileStorage: logFileStorage))
    }
}
