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
                                case .done:
                                    Text("✅")
                            }
                        }
                    }
                }
                CrashButton("Crash with fatalError()") {
                    fatalError("Manually triggered fatalError()")
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
        case done
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

        crashLogging.logErrorImmediately(
            error,
            userInfo: ["custom-userInfo-key": "custom-userInfo-value"]
        ) {
            sendErrorAndWaitStatus = .done
        }
    }
}

struct CrashButton: View {
    let titleKey: LocalizedStringKey
    let onCrashTapped: () -> Void

    let message = """
    For crashes to be reported, make sure no debbuger is attached.
    If running from Xcode, go to Debug > Detach from <app name>.
    Alternatively, stop the app from Xcode, then open it directly from the Simulator.
    After the crash, open the app directly from the Simulator.
    """

    @State var crashAlertPresented = false

    public init(_ titleKey: LocalizedStringKey, onCrashTapped: @escaping () -> Void) {
        self.titleKey = titleKey
        self.onCrashTapped = onCrashTapped
    }

    public var body: some View {
        if #available(iOS 15.0, *) {
            Button(titleKey) {
                crashAlertPresented = true
            }
            .alert(
                "Before you continue...",
                isPresented: $crashAlertPresented,
                actions: {
                    Button("Cancel", role: .cancel) {}
                    Button("Crash", role: .destructive, action: onCrashTapped)
                },
                message: {
                    Text(message)
                }
            )
        } else {
            // TODO: It's really about time we update Tracks to a later iOS deployment target
            preconditionFailure("Please run the demo app on iOS 15 or above...")
        }
    }
}
