import Sentry
import ObjectiveC

@objc
private protocol SentryClient_InternalMethods {
    @objc(prepareEvent:withScope:alwaysAttachStacktrace:isCrashEvent:)
    func prepareEvent(_ e: Sentry.Event,
                      withScope: Sentry.Scope,
                      alwaysAttachStacktrace: Bool,
                      isCrashEvent: Bool
    ) -> Sentry.Event?
}

extension Sentry.Client {
    /*
     * A wrapper around a private method in `SentryClient`. If it's unavailable (say the library
     changes),
     * the worst that should happen is that the stack trace is no longer available on events sent
     manually using this method.
     *
     * We can remove this once the Sentry SDK allows for capturing events and being notified once
     they're delivered.
     * ref: https://github.com/getsentry/sentry-cocoa/issues/660
     */
    @objc(addStackTraceToEvent:forClient:)
    func addStackTrace(to event: Sentry.Event, for client: Sentry.Client) -> Sentry.Event {

        let sel = #selector(SentryClient_InternalMethods.prepareEvent(_:withScope:alwaysAttachStacktrace:isCrashEvent:))

        if !client.responds(to: sel) {
            return event
        }

        guard let hub = SentrySDK._currentHub() else {
            // FIXME: !
            fatalError()
        }

        let scope = hub.scope
        guard let eventWithStackTrace = (self as AnyObject).prepareEvent(event, withScope: scope, alwaysAttachStacktrace: true, isCrashEvent: false)
        else {
            return event
        }

        if let stackTrace = eventWithStackTrace.threads?.first?.stacktrace {
            eventWithStackTrace.stacktrace = stackTrace
        }
        return event
    }
}

// TODO: If this works, extract in dedicated file
extension SentrySDK {

    // FIXME: Returning IUO only till everything compiles
    static func _currentHub() -> SentryHub? {
        return SentrySDK.perform(NSSelectorFromString("currentHub"))?.takeRetainedValue() as? SentryHub
    }
}
