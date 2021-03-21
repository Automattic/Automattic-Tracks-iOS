import Foundation

public struct ImmutableTracksEvent {
    public let uuid: UUID
    public let name: String
    public let date: Date

    public let userID: String
    public let username: String
    public let userAgent: String

    public let userType: TracksEventUserType

    public let eventProperties: [KeyValueType<String>]
    public let userProperties: [KeyValueType<String>]
    public let deviceProperties: [KeyValueType<String>]

    init?(_ event: TracksEventCoreData) {
        guard
            let uuid = UUID(uuidString: event.uuid),
            let userType = TracksEventUserType(rawValue: event.userType.uintValue)
        else {
            return nil
        }

        self.uuid = uuid
        self.name = event.eventName
        self.date = event.date

        self.userID = event.userID
        self.username = event.username
        self.userAgent = event.userAgent

        self.userType = userType

        if event.customProperties != nil {
            self.eventProperties = event.customProperties.compactMap {
                guard let key = $0.key as? String, let value = $0.value as? String else {
                    return nil
                }

                return KeyValueType(key: key, value: value)
            }
        } else {
            self.eventProperties = []
        }

        if event.userProperties != nil {
            self.userProperties = event.userProperties.compactMap {
                guard let key = $0.key as? String, let value = $0.value as? String else {
                    return nil
                }

                return KeyValueType(key: key, value: value)
            }
        } else {
            self.userProperties = []
        }

        if event.deviceInfo != nil {
            self.deviceProperties = event.deviceInfo.compactMap {
                guard let key = $0.key as? String, let value = $0.value as? String else {
                    return nil
                }

                return KeyValueType(key: key, value: value)
            }
        } else {
            self.deviceProperties = []
        }
    }
}

extension ImmutableTracksEvent: Identifiable {
    public var id: String {
        uuid.uuidString
    }
}
