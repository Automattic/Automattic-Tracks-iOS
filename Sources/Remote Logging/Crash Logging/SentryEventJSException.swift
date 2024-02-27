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
    override required init() {
        // All JavaScript exceptions should be trated as fatal errors.
        super.init(level: .fatal)
        // Setting the event's platform to JavaScript is required by Sentry to be processed as a JavaScript exception.
        // Otherwise, Sentry won't symbolicate the stack trace.
        self.platform = "javascript"
    }
    
    public static func initWithException(_ rawException: [AnyHashable: Any]) -> SentryEventJSException {
        let sentryEvent = self.init()
        
        // Generate exception based on JavaScript exception parameters.
        let sentryException = Exception(value: rawException["value"] as! String, type: rawException["type"] as! String)
        
        // Generate the stacktrace frames.
        var frames:[Frame] = []
        let stacktrace = rawException["stacktrace"] as! [[AnyHashable: Any]]
        for entry in stacktrace {
            let frame = Frame()
            frame.fileName = entry["filename"] as! String
            frame.function = entry["function"] as! String
            frame.inApp = true
            frame.lineNumber = entry["lineno"] as? NSNumber ?? 0
            frame.columnNumber = entry["colno"] as? NSNumber ?? 0
            frames.append(frame)
        }
        sentryException.stacktrace = SentryStacktrace(frames: frames, registers: [:])
        
        // Attach JavaScript exception to Sentry event.
        sentryEvent.exceptions = [sentryException]
        
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
