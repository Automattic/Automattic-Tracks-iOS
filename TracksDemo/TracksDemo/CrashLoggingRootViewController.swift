import SwiftUI
import AutomatticTracks

class CrashLoggingRootViewController: UIHostingController<CrashLoggingView> {

    let crashLogging = CrashLogging(dataProvider: CrashLoggingDataSource())

    init() {
        crashLogging.start()

        let rootView = CrashLoggingView(crashLogging: crashLogging)
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        crashLogging.start()

        let rootView = CrashLoggingView(crashLogging: crashLogging)
        super.init(coder: aDecoder, rootView: rootView)
    }
}
