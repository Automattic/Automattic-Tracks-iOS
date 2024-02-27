import Foundation
import Sentry

public struct JSException {
    public let type: String
    public let value: String
    public let stacktrace: [StacktraceLine]
    public let context: [String: Any]
    public let tags: [String: String]
    public let isHandled: Bool
    public let handledBy: String

    public init(type: String, value: String, stacktrace: [StacktraceLine], context: [String : Any], tags: [String : String], isHandled: Bool, handledBy: String) {
        self.type = type
        self.value = value
        self.stacktrace = stacktrace
        self.context = context
        self.tags = tags
        self.isHandled = isHandled
        self.handledBy = handledBy
    }
    
    public struct StacktraceLine {
        public let filename: String?
        public let function: String?
        public let lineno: NSNumber?
        public let colno: NSNumber?
        
        public init(filename: String?, function: String?, lineno: NSNumber?, colno: NSNumber?) {
            self.filename = filename
            self.function = function
            self.lineno = lineno
            self.colno = colno
        }
    }
}

public class SentryEventJSException: Event {
    required init() {
        // All JavaScript exceptions should be trated as fatal errors
        super.init(level: .fatal)
        // Setting the event's platform to JavaScript is required by Sentry to be processed
        // as a JavaScript exception. Otherwise, Sentry won't symbolicate the stack trace.
        self.platform = "javascript"
    }
    
    public static func initWithException(_ jsException: JSException) -> SentryEventJSException {
        let sentryEvent = self.init()
        
        // Generate exception based on JavaScript exception parameters
        let sentryException = Exception(value: jsException.value, type: jsException.type)
        
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
        sentryEvent.exceptions = [sentryException]
        
        // Set event context
        var context = sentryEvent.context ?? [:]
        context["react_native_context"] = jsException.context;
        sentryEvent.context = context
        
        // Set event tags
        let tags = sentryEvent.tags ?? [:]
        sentryEvent.tags = tags.merging(jsException.tags) { $1 }
        
        return sentryEvent
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
