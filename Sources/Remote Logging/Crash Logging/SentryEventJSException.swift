import Foundation
import Sentry

public protocol JSException {
    associatedtype StacktraceLine: JSStacktraceLine
    /// Source-map debug images that let Sentry symbolicate the minified stack
    /// frames via Debug IDs, independent of the (unstable) on-device file paths.
    /// Defaults to `NoJSDebugImage`, so existing conformers that don't provide
    /// debug images keep compiling and behaving unchanged.
    associatedtype DebugImage: JSDebugImage = NoJSDebugImage
    var type: String { get }
    var message: String { get }
    var stacktrace: [StacktraceLine] { get }
    var context: [String: Any] { get }
    var tags: [String: String] { get }
    var isHandled: Bool { get }
    var handledBy: String { get }
    var debugImages: [DebugImage] { get }
}

public extension JSException where DebugImage == NoJSDebugImage {
    /// Conformers that don't specify a `DebugImage` type report no debug images.
    var debugImages: [NoJSDebugImage] { [] }
}

public protocol JSStacktraceLine {
    var filename: String? { get }
    var function: String { get }
    var lineno: NSNumber? { get }
    var colno: NSNumber? { get }
}

/// A source-map debug image: pairs a minified file with the Debug ID that
/// identifies its source map, so Sentry can look up the map by ID.
public protocol JSDebugImage {
    /// The minified file the debug ID applies to (matches the stack frame's file).
    var codeFile: String { get }
    /// The Debug ID shared by the minified file and its uploaded source map.
    var debugID: String { get }
}

/// The default `JSException.DebugImage` type for conformers that supply no
/// source-map debug images. Never instantiated (the default `debugImages` is
/// always empty); it only satisfies the associated-type constraint.
public struct NoJSDebugImage: JSDebugImage {
    public var codeFile: String { "" }
    public var debugID: String { "" }
}

public class SentryEventJSException: Event {
    required init() {
        // All JavaScript exceptions should be trated as fatal errors
        super.init(level: .fatal)
        // Setting the event's platform to JavaScript is required by Sentry to be processed
        // as a JavaScript exception. Otherwise, Sentry won't symbolicate the stack trace.
        self.platform = "javascript"
    }

    public convenience init(jsException: any JSException) {
        self.init()

        // Generate exception based on JavaScript exception parameters
        let sentryException = Exception(value: jsException.message, type: jsException.type)

        // Generate the stacktrace frames
        let frames = jsException.stacktrace.map {
            let frame = Frame()
            frame.fileName = $0.filename
            frame.function = $0.function
            frame.inApp = true
            frame.lineNumber = $0.lineno
            frame.columnNumber = $0.colno
            return frame
        }
        sentryException.stacktrace = SentryStacktrace(frames: frames, registers: [:])

        // Add exception mechanism
        let mechanism = Mechanism(type: jsException.handledBy)
        mechanism.handled = jsException.isHandled ? 1 : 0
        sentryException.mechanism = mechanism

        // Attach JavaScript exception to Sentry event
        self.exceptions = [sentryException]

        // Set event context
        var context = self.context ?? [:]
        context["react_native_context"] = jsException.context
        self.context = context

        // Set event tags
        let tags = self.tags ?? [:]
        self.tags = tags.merging(jsException.tags) { $1 }

        // Attach source-map debug images (if provided) so Sentry can match the
        // uploaded source maps by Debug ID. This is required for JavaScript
        // running from unstable on-device paths (e.g. a WebView loading files
        // from a per-install bundle directory), where path-based matching fails.
        if !jsException.debugImages.isEmpty {
            self.debugMeta = jsException.debugImages.map {
                let image = DebugMeta()
                image.type = "sourcemap"
                image.codeFile = $0.codeFile
                image.debugID = $0.debugID
                return image
            }
        }
    }

    override public func serialize() -> [String: Any] {
        var serializedData = super.serialize()

        // By default, events generated in Sentry iOS SDK are tagged to "cocoa" platform.
        // Hence, we use the original platform set.
        serializedData["platform"] = self.platform

        // Remove metadata associated with the native exception, as it's not
        // needed for JavaScript exceptions. Preserve `debug_meta` when we've
        // attached source-map debug images, since those are required to
        // symbolicate the JavaScript stack trace.
        if (self.debugMeta ?? []).isEmpty {
            serializedData["debug_meta"] = nil
        }
        serializedData["threads"] = nil

        return serializedData
    }
}
