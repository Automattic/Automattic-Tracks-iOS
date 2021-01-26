import SwiftUI
import AutomatticTracks

class CrashLoggingRootViewController: UIHostingController<CrashLoggingView> {

    let crashLogging = try! CrashLogging(dataProvider: CrashLoggingDataSource()).start()

    init() {
        let rootView = CrashLoggingView(crashLogging: crashLogging)
        super.init(rootView: rootView)
    }

    @objc required dynamic init?(coder aDecoder: NSCoder) {
        let rootView = CrashLoggingView(crashLogging: crashLogging)
        super.init(coder: aDecoder, rootView: rootView)
    }
}
