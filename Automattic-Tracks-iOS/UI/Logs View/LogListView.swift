import Foundation
import SwiftUI

@available(iOS 14.0, OSX 11.0, *)
public struct LogListView: View {

    @State private var isShowingAlert = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    @ObservedObject
    var logFileStorage: LogFileStorage
//    let crashLogging: CrashLogging

    /// We can't observe an environment object, so instead we'll listen for the publisher to update values and copy them to the local state
//    @State var uploadState: EventLoggingPublisher.UploadState = .done

    public init(logFileStorage: LogFileStorage) {
        self.logFileStorage = logFileStorage
    }

    public var body: some View {

        Group {
            #if os(iOS)
            VStack {
                self.content
            }
            .navigationBarTitle("Log Upload Queue")
            .navigationBarItems(trailing: Button(action: addTestLogToQueue) {
                Image(systemName: "plus.circle")
            })
            .toolbar {
                ToolbarItem(placement: .bottomBar) {
//                    switch uploadState {
//                        case .uploading:
//                            Text("Uploading")
//                                .font(.caption)
//                        case .paused(let date):
//                            let dateString = DateFormatter.localizedString(
//                                from: date,
//                                dateStyle: .short,
//                                timeStyle: .medium
//                            )
//
//                            Text("Paused until \(dateString)")
//                                .font(.caption)
//                        case .done:
                            Text("Done")
                                .font(.caption)
//                    }
                }
            }
            #elseif os(macOS)
            VStack {
                Button(action: addTestLogToQueue, label: {
                    Image(systemName: "plus.circle")
                    Text("Create new Log File")
                }).padding()

                self.content

                Button(action: {}, label: {
                    Image(systemName: "square.and.arrow.up")
                    Text("Upload Log Files")
                }).padding()
            }
            #endif
        }
//        .onReceive(eventLoggingPublisher.$uploadState) {
//            self.uploadState = $0
//        }
    }

    var content: some View {
        Group {

            if logFileStorage.logFiles.isEmpty {
                EmptyView(text: "Log Upload Queue is Empty")
            } else {
                List(logFileStorage.logFiles) { logFile in
                    EncryptedLogFileCell(logFile: logFile)
                }
            }
        }
        .alert(isPresented: $isShowingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
        }
    }

    private func addTestLogToQueue() {
        do {
            /// For now, just enqueue any data
            let data = UUID().uuidString.data(using: .utf8)!

            let url = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(UUID().uuidString)
            try data.write(to: url)

            try logFileStorage.enqueueLogFileForUpload(LogFile(url: url))
        }
        catch let err {
            alertTitle = "Unable to create log"
            alertMessage = err.localizedDescription
            isShowingAlert = true
        }
    }
}

@available(iOS 14.0, OSX 11.0, *)
struct EncryptedLogFileCell: View {
    let logFile: LogFile

    var body: some View {
        NavigationLink(
            destination: LogDetailView(logFilePath: logFile.url),
            label: {
                VStack(alignment: .leading) {
                    Text(logFile.uuid)
                        .font(.body)

//                    if let date = logFile.date {
//                        Text(DateFormatter.localizedString(from: date, dateStyle: .short, timeStyle: .short))
//                            .font(.caption)
//                    }
                }
            })
    }
}
