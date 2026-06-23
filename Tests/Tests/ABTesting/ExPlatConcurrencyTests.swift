import Foundation
import Testing

#if SWIFT_PACKAGE
@testable import AutomatticExperiments
#else
@testable import AutomatticTracks
#endif

@Suite(.serialized)
struct ExPlatConcurrencyTests {

    private let configuration = ExPlatConfiguration(
        platform: "wpios_test",
        oAuthToken: nil,
        userAgent: nil,
        anonId: nil
    )

    // Reassigning `ExPlat.shared` on a background queue while reading it must not crash
    @Test func sharedLifecycleSurvivesConcurrentReassignmentAndReads() async {
        let iterations = 1_000

        _ = ExPlat(configuration: configuration, service: ExPlatServiceStub())

        await withCheckedContinuation { continuation in
            let group = DispatchGroup()

            // Reassign the global (releasing the previous instance) off the main thread
            group.enter()
            DispatchQueue.global().async {
                for _ in 0..<iterations {
                    _ = ExPlat(configuration: self.configuration, service: ExPlatServiceStub())
                }
                group.leave()
            }

            // Borrow the global and form `[weak self]` inside `refresh`
            group.enter()
            DispatchQueue.global().async {
                for _ in 0..<iterations {
                    ExPlat.shared?.refresh { }
                    _ = ExPlat.shared?.experiment("experiment")
                }
                group.leave()
            }

            group.notify(queue: .global()) {
                continuation.resume()
            }
        }

        #expect(ExPlat.shared != nil)

        ExPlat.shared = nil
    }
}

// Resolves `refresh` synchronously without hitting the network
private final class ExPlatServiceStub: ExPlatService {
    init() {
        super.init(configuration: ExPlatConfiguration(
            platform: "wpios_test",
            oAuthToken: nil,
            userAgent: nil,
            anonId: nil
        ))
    }

    override func getAssignments(completion: @escaping (Assignments?) -> Void) {
        completion(Assignments(ttl: 60, variations: ["experiment": "treatment"]))
    }
}
