import Sentry

extension Event {
    static func from(
        error: NSError,
        level: SentryLevel = .error,
        user: Sentry.User? = nil,
        timestamp: Date = Date(),
        extra: [String: Any] = [:]
    ) -> Event {
        let event = Event(level: level)

        let baseError: NSError = (error.userInfo[NSUnderlyingErrorKey] as? NSError) ?? error
        event.message = SentryMessage(formatted: baseError.debugDescription)

        /// The error code/domain can be used to reproduce the original error
        var mutableExtra = extra
        mutableExtra["error-code"] = error.code
        mutableExtra["error-domain"] = error.domain

        error.userInfo.forEach { key, value in
            mutableExtra[key] = value
        }

        event.timestamp = timestamp
        event.extra = mutableExtra
        event.user = user
        return event
    }
}
