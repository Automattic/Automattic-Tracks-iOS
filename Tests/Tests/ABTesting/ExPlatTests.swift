import XCTest
import OHHTTPStubs
import OHHTTPStubsSwift

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

    /// Tests the right assignments endpoint is called when ExPlat is configured through `TracksService`.
    ///
    func testAssignmentsEndpointWithAnonymousConfiguration() {
        // Given
        let expectation = XCTestExpectation(description: "The ExPlat assignments endpoint should have the right params")
        let experiment = "test"
        let anonId = "123"
        let eventNamePrefix = "wooios_test"
        let expectedEndpoint = Self.makeAssignmentsEndpoint(platform: eventNamePrefix, experiment: experiment, anonId: anonId)
        stub(condition: isAbsoluteURLString(expectedEndpoint)) { request in
            expectation.fulfill()
            return .init(data: Data(), statusCode: 200, headers: nil)
        }

        // When
        self.makeSharedExPlat(
            platform: nil,
            eventNamePrefix: eventNamePrefix,
            experiment: experiment,
            anonId: anonId
        )
        ExPlat.shared?.refresh()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    /// Tests the right assignments endpoint is called when ExPlat is configured through `TracksService`.
    ///
    func testAssignmentsEndpointWithUserAuthConfiguration() {
        // Given
        let expectation = XCTestExpectation(description: "The ExPlat assignments endpoint should have the right params")
        let experiment = "test"
        let platform = "wooios_test"
        let token = "abc"
        let expectedEndpoint = Self.makeAssignmentsEndpoint(platform: platform, experiment: experiment)
        stub(condition: isAbsoluteURLString(expectedEndpoint)) { request in
            XCTAssertEqual(request.allHTTPHeaderFields?["Authorization"], "Bearer \(token)")
            expectation.fulfill()
            return .init(data: Data(), statusCode: 200, headers: nil)
        }

        // When
        self.makeSharedExPlat(
            platform: platform,
            eventNamePrefix: "jpios",
            experiment: experiment,
            username: "foobar",
            userID: "123",
            wpComToken: token
        )
        ExPlat.shared?.refresh()

        // Then
        wait(for: [expectation], timeout: 1.0)
    }

    // MARK: - Helpers

    static func makeAssignmentsEndpoint(platform: String, experiment: String, anonId: String? = nil) -> String {
        let baseURL = "https://public-api.wordpress.com"
        let path = "wpcom/v2/experiments/0.1.0/assignments"
        var endpoint = "\(baseURL)/\(path)/\(platform)?_locale=en&experiment_names=\(experiment)"
        if let anonId {
            endpoint.append("&anon_id=\(anonId)")
        }
        return endpoint
    }

    private func makeTracksService(platform: String?, eventNamePrefix: String?) -> TracksService? {
        guard let tracksService = TracksService(contextManager: MockTracksContextManager()) else {
            return nil
        }
        tracksService.platform = platform
        tracksService.eventNamePrefix = eventNamePrefix
        return tracksService
    }

    private func makeSharedExPlat(platform: String?, eventNamePrefix: String?, experiment: String, anonId: String?) {
        self.addTeardownBlock {
            ExPlat.shared = nil
        }
        guard let tracksService = makeTracksService(platform: platform, eventNamePrefix: eventNamePrefix) else {
            return
        }
        tracksService.switchToAnonymousUser(withAnonymousID: anonId)
        guard let exPlat = ExPlat.shared else {
            return
        }
        exPlat.register(experiments: [experiment])
    }

    private func makeSharedExPlat(
        platform: String?,
        eventNamePrefix: String?,
        experiment: String,
        username: String,
        userID: String,
        wpComToken: String
    ) {
        self.addTeardownBlock {
            ExPlat.shared = nil
        }
        guard let tracksService = makeTracksService(platform: platform, eventNamePrefix: eventNamePrefix) else {
            return
        }
        tracksService.switchToAuthenticatedUser(withUsername: username, userID: userID, wpComToken: wpComToken, skipAliasEventCreation: true)
        guard let exPlat = ExPlat.shared else {
            return
        }
        exPlat.register(experiments: [experiment])
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
