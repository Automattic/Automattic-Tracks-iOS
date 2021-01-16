import SwiftUI
import AutomatticTracks

class CrashLoggingRootViewController: NSHostingController<CrashLoggingView> {

    let crashLogging = CrashLogging(dataProvider: CrashLoggingDataSource())

    init() {
        let rootView = CrashLoggingView(crashLogging: crashLogging)
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        let rootView = CrashLoggingView(crashLogging: crashLogging)
        super.init(coder: aDecoder, rootView: rootView)
    }
}
