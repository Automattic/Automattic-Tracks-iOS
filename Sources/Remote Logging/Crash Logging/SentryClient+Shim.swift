import Sentry


@objc
private protocol SentryClientInternalMethods {
    @objc(prepareEvent:withScope:alwaysAttachStacktrace:isCrashEvent:)
    func prepareEvent(_ e: Sentry.Event,
                      withScope: Sentry.Scope,
                      alwaysAttachStacktrace: Bool,
                      isCrashEvent: Bool
    ) -> Sentry.Event?
    
    @objc(threadInspector)
    func threadInspector() -> Any
}

@objc
private protocol SentryThreadInspectorInternalMethods {
    @objc(getCurrentThreads)
    func getCurrentThreads() -> [Sentry.Thread]
    
}

extension Sentry.Client {
    
    /// Returns an array of threads for the current stack trace.  This hack is needed because we don't have
    /// any public mechanism to access the stack trace threads to add them to our custom events.
    ///
    /// Ref: https://github.com/getsentry/sentry-cocoa/issues/1451#issuecomment-1240782406
    ///
    func currentThreads() -> [Sentry.Thread] {
        let threadInspectorSelector = #selector(SentryClientInternalMethods.threadInspector)
        
        guard responds(to: threadInspectorSelector) else {
            return []
        }
        
        let threadInspector = perform(threadInspectorSelector).takeUnretainedValue()
        let getCurrentThreadsSelector = #selector(SentryThreadInspectorInternalMethods.getCurrentThreads)
        
        guard threadInspector.responds(to: getCurrentThreadsSelector) else {
            return []
        }
        
        let threads = threadInspector.perform(getCurrentThreadsSelector).takeUnretainedValue() as? [Sentry.Thread]
        return threads ?? []
    }
}
