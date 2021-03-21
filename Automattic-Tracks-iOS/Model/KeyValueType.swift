import Foundation

public struct KeyValueType<T>: Identifiable {
    public let id: String
    public let key: String
    public let value: T

    init(key: String, value: T) {
        self.id = key
        self.key = key
        self.value = value
    }
}
