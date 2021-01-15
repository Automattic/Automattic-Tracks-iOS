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

    var body: some View {
        #if os(macOS)
        LogView(text: logFileContents).padding()
        #else
        LogView(text: logFileContents)
            .navigationTitle("Log View")
        #endif
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
