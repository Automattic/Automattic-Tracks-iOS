import XCTest
import Sentry

#if SWIFT_PACKAGE
@testable import AutomatticRemoteLogging
#else
@testable import AutomatticTracks
#endif

class SentryEventJSExceptionTests: XCTestCase {

    func testSerializesSourceMapDebugImagesWhenProvided() throws {
        let exception = MockJSException(debugImages: [
            MockJSDebugImage(codeFile: "~/assets/index-abc123.js", debugID: "d552288e-c4cc-5fbc-b188-eec3bf468157")
        ])

        let serialized = SentryEventJSException(jsException: exception).serialize()

        let debugMeta = try XCTUnwrap(serialized["debug_meta"] as? [String: Any])
        let images = try XCTUnwrap(debugMeta["images"] as? [[String: Any]])
        XCTAssertEqual(images.count, 1)
        XCTAssertEqual(images[0]["type"] as? String, "sourcemap")
        XCTAssertEqual(images[0]["code_file"] as? String, "~/assets/index-abc123.js")
        XCTAssertEqual(images[0]["debug_id"] as? String, "d552288e-c4cc-5fbc-b188-eec3bf468157")
    }

    func testOmitsDebugMetaWhenNoDebugImagesProvided() {
        // Mirrors the existing React Native path, which supplies no debug images:
        // `debug_meta` must stay stripped so behavior is unchanged.
        let exception = MockJSException(debugImages: [])

        let serialized = SentryEventJSException(jsException: exception).serialize()

        XCTAssertNil(serialized["debug_meta"])
    }

    func testDebugImagesDefaultsToEmptyForConformersThatDoNotProvideThem() {
        // A conformer that doesn't implement `debugImages` relies on the protocol
        // extension default, keeping existing conformers source-compatible.
        let exception = LegacyJSException()

        XCTAssertTrue(exception.debugImages.isEmpty)

        let serialized = SentryEventJSException(jsException: exception).serialize()
        XCTAssertNil(serialized["debug_meta"])
    }
}

private struct MockJSDebugImage: JSDebugImage {
    let codeFile: String
    let debugID: String
}

private struct MockStacktraceLine: JSStacktraceLine {
    var filename: String? = "~/assets/index-abc123.js"
    var function: String = "boom"
    var lineno: NSNumber? = 22
    var colno: NSNumber? = 247
}

private struct MockJSException: JSException {
    var type: String = "Error"
    var message: String = "Boom"
    var stacktrace: [MockStacktraceLine] = [MockStacktraceLine()]
    var context: [String: Any] = [:]
    var tags: [String: String] = [:]
    var isHandled: Bool = false
    var handledBy: String = "window.error"
    var debugImages: [MockJSDebugImage]
}

/// A conformer that does NOT provide `debugImages`, exercising the protocol
/// extension default (the React Native compatibility path).
private struct LegacyJSException: JSException {
    var type: String = "Error"
    var message: String = "Boom"
    var stacktrace: [MockStacktraceLine] = [MockStacktraceLine()]
    var context: [String: Any] = [:]
    var tags: [String: String] = [:]
    var isHandled: Bool = false
    var handledBy: String = "window.error"
}
