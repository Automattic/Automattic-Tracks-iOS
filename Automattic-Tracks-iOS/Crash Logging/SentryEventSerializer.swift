import Foundation
import Sentry

struct SentryEventSerializer {

    private let dsn: String
    private let jsonEncoder: JSONEncoder

    var events = [String: Event]()

    init(dsn: String) {
        self.dsn = dsn
        self.jsonEncoder = JSONEncoder()
        self.jsonEncoder.dateEncodingStrategy = .iso8601
    }

    mutating func add(event: Event, filename: String = UUID().uuidString) {
        events[filename] = event
    }

    func serialize(eventId: UUID = UUID()) throws -> Data {
        /// Turn the UUID into a `SentryId` temporarily, just in case they ever change the API on us – that way it won't fail
        let header = SentryHeader(event_id: SentryId.init(uuid: eventId).sentryIdString, dsn: dsn)

        var entries = [
            try encode(header),
        ]

        try events.forEach {
            let data = try encode($0.value.serialize())
            let header = AttachmentHeader(type: "event", length: data.count, content_type: "application/json", filename: $0.key)
            entries.append(try encode(header))
            entries.append(data)
        }

        return Data(entries.joined(separator: "\n".bytes))
    }

    private func encode<T>(_ object: T) throws -> Data where T: Encodable {
        try jsonEncoder.encode(object)
    }

    private func encode(_ dictionary: [String: Any]) throws -> Data {
        try JSONSerialization.data(withJSONObject: dictionary, options: [])
    }
}

struct SentryHeader: Codable {
    let event_id: String
    let dsn: String
}

struct AttachmentHeader: Codable {
    let type: String
    let length: Int
    let content_type: String
    let filename: String
}
