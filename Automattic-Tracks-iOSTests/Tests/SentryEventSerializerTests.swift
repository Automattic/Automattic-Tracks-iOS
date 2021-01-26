import XCTest
@testable import AutomatticTracks
import Sentry

class SentryEventSerializerTests: XCTestCase {

    func testThatHeaderContainsDSN() throws {
        let dsn = UUID().uuidString
        let serialized = try! SentryEventSerializer(dsn: dsn).serialize(eventId: UUID())
        let decoded = try decoder.decode(SentryHeader.self, from: serialized)
        XCTAssertEqual(dsn, decoded.dsn)
    }

    func testThatHeaderContainsEventId() throws {
        let id = UUID()
        let serialized = try! SentryEventSerializer(dsn: UUID().uuidString).serialize(eventId: id)
        let decoded = try decoder.decode(SentryHeader.self, from: serialized)
        XCTAssertEqual(id.uuidString.lowercased().replacingOccurrences(of: "-", with: ""), decoded.event_id)
    }

    func testThatEnvelopeContainsEventHeaderAndBody() throws {
        var serializer = SentryEventSerializer(dsn: UUID().uuidString)
        serializer.add(event: Event(level: .debug))
        let serialized = try serializer.serialize(eventId: UUID())
        XCTAssertEqual(3, serialized.split(separator: "\n".bytes.first!).count)
    }

    ///
    /// Helpers
    ///
    private var decoder: JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }
}
