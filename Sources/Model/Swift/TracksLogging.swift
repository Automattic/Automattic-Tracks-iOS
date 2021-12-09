import Foundation

#if SWIFT_PACKAGE
import AutomatticTracksModelObjC
#endif

// The Swift versions of these functions do not accept format strings
// and arguments; use string interpolation instead
public func TracksLogError(_ str: String) {
    TracksLogging.delegate?.logError(str)
}

public func TracksLogWarn(_ str: String) {
    TracksLogging.delegate?.logWarning(str)
}

public func TracksLogInfo(_ str: String) {
    TracksLogging.delegate?.logInfo(str)
}

public func TracksLogDebug(_ str: String) {
    TracksLogging.delegate?.logDebug(str)
}

public func TracksLogVerbose(_ str: String) {
    TracksLogging.delegate?.logVerbose(str)
}



public class TracksLogging: NSObject, TracksLoggingConfiguration {

    private static var _delegate: TracksLoggingDelegate?

    @objc public static var delegate: TracksLoggingDelegate? {
        get {
            #if DEBUG
            if _delegate == nil {
                print("*** A Tracks logging delegate has not been configured, so Tracks will log to the console. If you would like to redirect logging to an existing logging system, assign a logging delegate to TracksLogging.delegate. (You may need to import AutomatticTracksModel, depending on what else you have imported.)")
                _delegate = DefaultTracksLogging()
            }
            #endif

            return _delegate
        }
        set {
            _delegate = newValue
        }
    }
}

private class DefaultTracksLogging: NSObject, TracksLoggingDelegate {

    func logPanic(_ str: String) {
        print("Tracks <☠️>: \(str)")
    }

    func logError(_ str: String) {
        print("Tracks <E>: \(str)")
    }

    func logWarning(_ str: String) {
        print("Tracks <W>: \(str)")
    }

    func logInfo(_ str: String) {
        print("Tracks <I>: \(str)")
    }

    func logDebug(_ str: String) {
        print("Tracks <D>: \(str)")
    }

    func logVerbose(_ str: String) {
        print("Tracks <V>: \(str)")
    }
}
