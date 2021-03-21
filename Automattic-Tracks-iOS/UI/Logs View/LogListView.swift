import Foundation
import SwiftUI

public protocol LogSampleContentProvider {
    var sampleContent: [URL] { get }
}

@available(iOS 14.0, OSX 11.0, *)
public struct LogListView: View {

    @State private var isShowingAlert = false
    @State private var alertTitle: String = ""
    @State private var alertMessage: String = ""

    @ObservedObject
    var logFileStorage: LogFileStorage

    @ObservedObject
    var eventLoggingEmitter = EventLoggingEmitter()

    let sampleContentProvider: LogSampleContentProvider

//    let crashLogging: CrashLogging

    /// We can't observe an environment object, so instead we'll listen for the publisher to update values and copy them to the local state
//    @State var uploadState: EventLoggingPublisher.UploadState = .done

    public init(logFileStorage: LogFileStorage, sampleContentProvider: LogSampleContentProvider) {
        self.logFileStorage = logFileStorage
        self.sampleContentProvider = sampleContentProvider
    }

    public var body: some View {
        Group {
            #if os(macOS)
            VStack {
                logFileList
                HStack {
                    uploadLogsButton
                    Spacer()
                    addTestLogToQueueButton
                }
                .padding()
            }
            #else
            logFileList.navigationBarItems(
                leading: uploadLogsButton,
                trailing: addTestLogToQueueButton
            ).navigationBarTitle("Encrypted Logs", displayMode: .inline)
            #endif
        }.alert(isPresented: $isShowingAlert) {
            Alert(title: Text(alertTitle), message: Text(alertMessage), dismissButton: .default(Text("Ok")))
        }
    }

    var uploadLogsButton: some View {
        Group {
            switch eventLoggingEmitter.uploadState {
                case .paused(let date):
                    if date == nil {
                        Button(action: uploadLogFiles) {
                            Image(systemName: "square.and.arrow.up")
                        }
                    }
                case .cancelled:
                    Image(systemName: "xmark.octagon")
                case .done:
                    Button(action: uploadLogFiles) {
                        Image(systemName: "square.and.arrow.up")
                    }
                case .uploading:
                    ProgressView()
            }
        }
    }

    var addTestLogToQueueButton: some View {
        Button(action: addTestLogToQueue) {
            Image(systemName: "plus.circle")
        }
    }

    var logFileList: some View {
        Group {
            if logFileStorage.logFiles.isEmpty {
                EmptyView(text: "Log Upload Queue is Empty")
            } else {
                List(logFileStorage.logFiles) { logFile in
                    EncryptedLogFileCell(logFile: logFile)
                }
            }
        }
    }

}

// MARK: – Actions
@available(iOS 14.0, OSX 11.0, *)
extension LogListView {
    private func addTestLogToQueue() {
        do {
            guard let contentUrl = sampleContentProvider.sampleContent.randomElement() else {
                alertTitle = "Unable to create log"
                alertMessage = "No sample content provided"
                isShowingAlert = true
                return
            }

            try logFileStorage.enqueueLogFileForUpload(LogFile(url: contentUrl))
        }
        catch let err {
            alertTitle = "Unable to create log"
            alertMessage = err.localizedDescription
            isShowingAlert = true
        }
    }

    private func uploadLogFiles() {
        logFileStorage.uploadQueuedLogFiles()
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
                    Text(DateFormatter.localizedString(from: logFile.displayCreationDate, dateStyle: .short, timeStyle: .short))
                        .font(.body)

                    Text(logFile.displayText)
                        .font(.caption)
                        .lineLimit(1)
                }
            })
    }
}

@available(iOS 13.0, OSX 10.15, *)
extension LogFile {
    var displayCreationDate: Date {
        return creationDate ?? Date()
    }

    var displayText: String {
        let fileHandle = FileHandle(forReadingAtPath: url.path)
        defer {
            try? fileHandle?.close()
        }

        guard
            let data = fileHandle?.readData(ofLength: 512),
            let text = String(data: data, encoding: .utf8)?.trimmingCharacters(in: .whitespacesAndNewlines)
        else {
            return "Unable to read file"
        }

        return text
    }
}
