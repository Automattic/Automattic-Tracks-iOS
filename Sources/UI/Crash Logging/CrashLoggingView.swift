import SwiftUI
import Sentry

#if SWIFT_PACKAGE
import AutomatticRemoteLogging
#endif

@available(iOS 13.0, OSX 10.15, *)
public struct CrashLoggingView: View {

    @State
    var sendErrorAndWaitStatus: SendErrorAndWaitStatus = .none

    @State
    var sendingError: Error?

    private let crashLogging: CrashLogging

    public init(crashLogging: CrashLogging) {
        self.crashLogging = crashLogging
    }

    public var body: some View {
        Form {
            Section(header: Text("Actions")) {
                Button("Send Test Crash", action: sendTestCrash)
                Button("Send Test Event", action: sendTestEvent)
                Button("Send Test Error", action: sendTestError)
                HStack {
                    Button(action: sendErrorAndWait) {
                        HStack {
                            Text("Send Error and Wait")

                            /// Nicely align the icon to the right on iOS but don't leave
                            /// a weird-shaped button on macOS
                            #if os(iOS)
                            Spacer()
                            #endif

                            switch sendErrorAndWaitStatus {
                                case .none:
                                    Group {} /// An empty view
                                case .uploading:
                                    Text("⏳")
                                case .success:
                                    Text("✅")
                                case .error:
                                    Text("⚠️")
                            }
                        }
                    }
                }
            }

            /// Push the form to the top of the screen
            #if os(macOS)
            Spacer()
            #endif
        }
    }


    enum SendErrorAndWaitStatus {
        case none
        case uploading
        case success
        case error
    }
}

// MARK: - Actions
@available(iOS 13.0, OSX 10.15, *)
extension CrashLoggingView {
    private func sendTestCrash() {
        crashLogging.crash()
    }

    private func sendTestEvent() {
        crashLogging.logMessage("Test Event \(UUID().uuidString)")
    }

    private func sendTestError() {
        do {
            let path = FileManager.default
                .temporaryDirectory
                .appendingPathComponent(UUID().uuidString)
                .path
            let _ = try Data(contentsOf: URL(fileURLWithPath: path))
        } catch let err {
            crashLogging.logError(err)
        }
    }

    private func sendErrorAndWait() {
        sendErrorAndWaitStatus = .uploading

        let error = SentryTestError(title: "Test Error")

        do {
            try crashLogging.logErrorImmediately(error) {
                sendErrorAndWaitStatus = .success
            }
        } catch let err {
            sendingError = err
            sendErrorAndWaitStatus = .error
        }
    }
}
