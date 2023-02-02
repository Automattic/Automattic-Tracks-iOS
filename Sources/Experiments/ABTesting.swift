import Foundation

public enum Variation: Equatable, Codable {
    case control
    case treatment
    case customTreatment(name: String)
}

/// A protocol that defines a A/B Testing provider
///
public protocol ABTesting {
    /// Refresh the assigned experiments
    func refresh(completion: (() -> Void)?)

    /// Return an experiment variation
    func experiment(_ name: String) -> Variation?
}
