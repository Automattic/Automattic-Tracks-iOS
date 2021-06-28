import XCTest

@testable import AutomatticTracks

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
            XCTAssertEqual(abTesting.experiment("experiment"), .control)
            XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment(nil))
            XCTAssertEqual(abTesting.experiment("experiment_multiple_variation"), .treatment("another_treatment"))
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
                XCTAssertEqual(abTesting.experiment("experiment"), .treatment(nil))

                // Should not change "experiment" to control
                serviceMock.experimentVariation = "control"
                abTesting.refreshIfNeeded {
                    XCTAssertEqual(abTesting.experiment("experiment"), .treatment(nil))
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
                XCTAssertEqual(abTesting.experiment("experiment"), .control)
                XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment(nil))
                XCTAssertEqual(abTesting.experiment("experiment_multiple_variation"), .treatment("another_treatment"))
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
