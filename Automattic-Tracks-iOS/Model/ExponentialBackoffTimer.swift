import Foundation

struct ExponentialBackoffTimer {

    /// The current amount of delay, in seconds
    private(set) var delay: Int

    /// The current exponent
    private var exponent: Int = 1

    /// Keep a copy of the initial delay to allow reset
    private let initialDelay: Int = 0

    /// The minimum allowed delay
    private let minimumDelay: Int

    /// The maximum allowed delay
    private let maximumDelay: Int

    /// Create a backoff timer with an optional initial duration.
    ///
    /// - Parameters:
    ///   - minimumDelay: The smallest possible delay (specified in seconds). Must be greater than one.
    ///   - maximumDelay: The largest possible delay (specified in seconds). Must be greater than one, and greater than the initial delay.
    ///            The default is approximately one day.
    init(minimumDelay: Int = 2, maximumDelay: Int = 86_400) {
        precondition(minimumDelay > 1, "The initial delay must be greater than 1 – otherwise it will never increase")
        precondition(maximumDelay > minimumDelay, "The limit must be greater than the initial delay")
        precondition(maximumDelay < Int32.max / 2, "The limit must be less than Int32.max / 2 to avoid overflow")
        self.delay = initialDelay
        self.minimumDelay = minimumDelay
        self.maximumDelay = maximumDelay
    }

    /// Exponentially increase the delay (up to `maximumDelay`)
    mutating func increment() {
        delay = Int(pow(Double(minimumDelay), Double(exponent)))
        exponent += 1

        if delay > maximumDelay {
            delay = maximumDelay
        }

        next = .now() + .seconds(delay)
        nextDate = Date(timeIntervalSinceNow: TimeInterval(delay))
    }

    /// Reset the delay to zero
    mutating func reset() {
        delay = initialDelay
        self.next = .now()
        self.nextDate = Date()
    }

    /// A `DispatchTime` compatible with `DispatchQueue.asyncAfter` that represents the next time the timer should fire.
    private(set) internal var next: DispatchTime = .now()

    /// A `Date` representation of `next`.
    private(set) var nextDate: Date = Date()
}
