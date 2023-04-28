import XCTest

#if SWIFT_PACKAGE
@testable import AutomatticExperiments
@testable import AutomatticTracksEvents
#else
@testable import AutomatticTracks
#endif

class ExPlatTests: XCTestCase {

    var exPlatTestConfiguration = ExPlatConfiguration(
        platform: "wpios_test",
        oAuthToken: nil,
        userAgent: nil,
        anonId: nil
    )

    var tracksService: TracksService!

    override func setUp() {
        let contextManager = MockTracksContextManager()
        self.tracksService = TracksService(contextManager: contextManager)
    }

    override func tearDown() {
        ExPlat.shared = nil
    }

    // Save the returned experiments variation
    //
    func testRefresh() {
        let expectation = XCTestExpectation(description: "Save experiments")
        let abTesting = ExPlat(configuration: exPlatTestConfiguration, service: ExPlatServiceMock())

        abTesting.refresh {
            XCTAssertNil(abTesting.experiment("experiment"))
            XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment)
            XCTAssertEqual(abTesting.experiment("experiment_multiple_variation"), .customTreatment(name: "another_treatment"))
            expectation.fulfill()
        }

        wait(for: [expectation], timeout: 2.0)
    }

    // Does not refresh if ttl hasn't expired
    //
    func testRefreshIfNeededOnlyAfterExpiredTtl() {
        let expectation = XCTestExpectation(description: "Save experiments")
        let serviceMock = ExPlatServiceMock()
        serviceMock.ttl = 0
        let abTesting = ExPlat(configuration: exPlatTestConfiguration, service: serviceMock)

        abTesting.refresh {

            // Should change "experiment" to treatment
            serviceMock.ttl = 60
            serviceMock.experimentVariation = "treatment"
            abTesting.refreshIfNeeded {
                XCTAssertEqual(abTesting.experiment("experiment"), .treatment)

                // Should not change "experiment" to control
                serviceMock.experimentVariation = "control"
                abTesting.refreshIfNeeded {
                    XCTAssertEqual(abTesting.experiment("experiment"), .treatment)
                    expectation.fulfill()
                }
            }
        }



        wait(for: [expectation], timeout: 2.0)
    }

    // Keep the already saved experiments in case of a failure
    //
    func testError() {
        let expectation = XCTestExpectation(description: "Keep experiments")
        let serviceMock = ExPlatServiceMock()
        let abTesting = ExPlat(configuration: exPlatTestConfiguration, service: serviceMock)
        abTesting.refresh {

            serviceMock.returnAssignments = false
            abTesting.refresh {
                XCTAssertNil(abTesting.experiment("experiment"))
                XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment)
                XCTAssertEqual(abTesting.experiment("experiment_multiple_variation"), .customTreatment(name: "another_treatment"))
                expectation.fulfill()
            }

        }

        wait(for: [expectation], timeout: 2.0)
    }

    // Add the experiment names into the service
    //
    func testRegister() {
        let serviceMock = ExPlatServiceMock()
        let abTesting = ExPlat(configuration: exPlatTestConfiguration, service: serviceMock)

        abTesting.register(experiments: ["foo", "bar"])

        XCTAssertEqual(serviceMock.experimentNames, ["foo", "bar"])
    }

    // Add the experiment names into the service
    //
    func testRegisteredEventsAfterNewConfiguration() {
        let serviceMock = ExPlatServiceMock()
        let abTesting = ExPlat(configuration: exPlatTestConfiguration, service: serviceMock)
        abTesting.register(experiments: ["foo", "bar"])

        ExPlat.configure(platform: "ios", oAuthToken: nil, userAgent: nil, anonId: nil)

        XCTAssertEqual(ExPlat.shared?.experimentNames, ["foo", "bar"])
    }

    // Tests ExPlat anonymous configuration using TracksService.
    //
    func testTracksServiceAnonymousConfiguration() {
        // Given
        let eventNamePrefix = "wooios"
        let anonymousId = "123"
        self.tracksService.platform = nil
        self.tracksService.eventNamePrefix = eventNamePrefix

        // When
        self.tracksService.switchToAnonymousUser(withAnonymousID: anonymousId)

        // Then
#if os(iOS)
        let exPlat = ExPlat.shared
        XCTAssertNotNil(exPlat)
        XCTAssertEqual(exPlat?.platform, eventNamePrefix)
        XCTAssertEqual(exPlat?.oAuthToken, nil)
        XCTAssertEqual(exPlat?.anonId, anonymousId)
#else
        XCTAssertNil(ExPlat.shared)
#endif
    }

    // Tests ExPlat user authenticated configuration using TracksService.
    //
    func testTracksServiceUserAuthConfiguration() {
        // Given
        let username = "foobar"
        let userID = "123"
        let wpComToken = "abc"
        let platform = "wpios"
        let eventNamePrefix = "jpios"
        let skipAliasEventCreation = true
        self.tracksService.platform = platform
        self.tracksService.eventNamePrefix = eventNamePrefix

        // When
        self.tracksService.switchToAuthenticatedUser(withUsername: username, userID: userID, wpComToken: wpComToken, skipAliasEventCreation: skipAliasEventCreation)

        // Then
#if os(iOS)
        let exPlat = ExPlat.shared
        XCTAssertNotNil(exPlat)
        XCTAssertEqual(exPlat?.platform, platform)
        XCTAssertEqual(exPlat?.oAuthToken, wpComToken)
        XCTAssertEqual(exPlat?.anonId, nil)
#else
        XCTAssertNil(ExPlat.shared)
#endif
    }
}

private class ExPlatServiceMock: ExPlatService {
    var returnAssignments = true
    var ttl = 60
    var experimentVariation: String? = nil

    init() {
        super.init(configuration: ExPlatConfiguration(
            platform: "wpios_test",
            oAuthToken: nil,
            userAgent: nil,
            anonId: nil
        ))
    }

    override func getAssignments(completion: @escaping (Assignments?) -> Void) {
        guard returnAssignments else {
            completion(nil)
            return
        }

        completion(
            Assignments(
                ttl: ttl,
                variations: [
                    "experiment": experimentVariation,
                    "another_experiment": "treatment",
                    "experiment_multiple_variation": "another_treatment"
                ]
            )
        )
    }
}
