import SwiftUI

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

@available(iOS 14.0, OSX 11.0, *)
struct LogDetailView: View {

    /// A URL containing the file path on the local device to this log
    let logFilePath: URL

    var logFileContents: String {
        do {
            return try String(contentsOf: logFilePath)
        } catch let err {
            return err.localizedDescription
        }
    }

    @State
    var didCopy: Bool = false

    var body: some View {
        #if os(macOS)
        VStack {
            fileHeader
            LogView(text: logFileContents).padding()
        }

        #else
        VStack {
            fileHeader
            Divider()
            LogView(text: logFileContents)
        }
        .navigationTitle("Log View")
        #endif
    }

    var fileHeader: some View {
        HStack {
            VStack(alignment: .leading) {
                Text("Log File ID:").font(.caption)
                Text(logFilePath.lastPathComponent)
                    .lineLimit(1)
            }
            Spacer()

            Group {
                if didCopy {
                    Image(systemName: "checkmark.circle")
                        .foregroundColor(.green)
                } else {
                    Button(action: didTapCopyButton) {
                        Image(systemName: "doc.on.doc")
                    }
                }
            }
        }.padding()
    }

    private func didTapCopyButton() {
        #if os(macOS)
        let pasteboard = NSPasteboard.general
        pasteboard.declareTypes([.string], owner: nil)
        pasteboard.setString(logFilePath.lastPathComponent, forType: .string)
        #else
        UIPasteboard.general.string = logFilePath.lastPathComponent
        #endif

        didCopy = true
    }
}

#if os(iOS) || os(watchOS) || os(tvOS)
@available(iOS 14.0, *)
struct LogView: UIViewRepresentable {
    private let text: String

    init(text: String) {
        self.text = text
    }

    func makeUIView(context: Context) -> UITextView {
        let view = UITextView()
        view.isSelectable = true
        view.isEditable = false
        view.text = text

        let systemFont = UIFont.preferredFont(forTextStyle: .body)
        view.font = .monospacedSystemFont(ofSize: systemFont.pointSize, weight: .regular)

        return view
    }

    func updateUIView(_ uiView: UITextView, context: Context) {
        /// Nothing needs to be done here
    }
}
#endif

#if os(macOS)
@available(OSX 11.0, *)
struct LogView: NSViewRepresentable {
    private let text: String

    private let scrollView = NSTextView.scrollableTextView()

    init(text: String) {
        self.text = text
    }

    func makeNSView(context: Context) -> some NSView {

        if let textView = scrollView.documentView as? NSTextView {
            textView.isSelectable = true
            textView.isEditable = false
            textView.string = text

            textView.textContainer?.widthTracksTextView = true
        }

        return scrollView
    }

    func updateNSView(_ nsView: NSViewType, context: Context) {

    }
}
#endif
