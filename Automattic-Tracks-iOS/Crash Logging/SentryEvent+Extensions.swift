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

        if let underlyingError = error.userInfo[NSUnderlyingErrorKey] as? NSError {
            event.message = SentryMessage(formatted: underlyingError.debugDescription)
        } else {
            event.message = SentryMessage(formatted: error.debugDescription)
        }

        /// The error code/domain can be used to reproduce the original error
        var mutableExtra = extra
        mutableExtra["error-code"] = error.code
        mutableExtra["error-domain"] = error.domain

        error.userInfo.forEach { (key, value) in
            mutableExtra[key] = value
        }

        event.timestamp = timestamp
        event.extra = [String:Any](uniqueKeysWithValues: mutableExtra.sorted { $0.key > $1.key })
        event.user = user
        return event
    }
}
