import SwiftUI
import Sentry

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

    private func sendErrorAndWait() {
        sendErrorAndWaitStatus = .uploading

        let error = SentryTestError(title: "Test Error")

        do {
            try crashLogging.logErrorImmediately(error) { result in
                switch result {
                    case .success:
                        sendErrorAndWaitStatus = .success
                    case .failure(let err):
                        sendingError = err
                        sendErrorAndWaitStatus = .error
                }
            }
        } catch let err {
            sendingError = err
            sendErrorAndWaitStatus = .error
        }
    }
}
