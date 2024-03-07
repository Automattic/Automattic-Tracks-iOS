import Foundation
import Sentry

public protocol JSException {
    associatedtype StacktraceLine: JSStacktraceLine
    var type: String { get }
    var message: String { get }
    var stacktrace: [StacktraceLine] { get }
    var context: [String: Any] { get }
    var tags: [String: String] { get }
    var isHandled: Bool { get }
    var handledBy: String { get }
}

public protocol JSStacktraceLine {
    var filename: String? { get }
    var function: String { get }
    var lineno: NSNumber? { get }
    var colno: NSNumber? { get }
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
        context["react_native_context"] = jsException.context;
        self.context = context
        
        // Set event tags
        let tags = self.tags ?? [:]
        self.tags = tags.merging(jsException.tags) { $1 }
    }
    
    override public func serialize() -> [String : Any] {
        var serializedData = super.serialize()
        
        // By default, events generated in Sentry iOS SDK are tagged to "cocoa" platform.
        // Hence, we use the original platform set.
        serializedData["platform"] = self.platform
        
        // Removing metadata associated with native exception, as it's not needed for JavaScript exceptions.
        serializedData["debug_meta"] = nil
        serializedData["threads"] = nil
        
        return serializedData
    }
}
