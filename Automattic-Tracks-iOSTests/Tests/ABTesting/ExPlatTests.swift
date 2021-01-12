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
            XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment)
            expectation.fulfill()
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
                XCTAssertEqual(abTesting.experiment("another_experiment"), .treatment)
                expectation.fulfill()
            }

        }

        wait(for: [expectation], timeout: 2.0)
    }

    // Schedule a timer to automatically refresh
    //
    func testScheduleRefresh() {
        let expectation = XCTestExpectation(description: "Automatically refresh")
        let serviceMock = ExPlatServiceMock()
        let abTesting = ExPlat(configuration: exPlatTestConfiguration, service: serviceMock)
        abTesting.refresh {

            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                XCTAssertTrue(abTesting.scheduledTimer!.isValid)
                XCTAssertEqual(round(abTesting.scheduledTimer!.timeInterval), 60)
                expectation.fulfill()
            }

        }

        wait(for: [expectation], timeout: 2.0)
    }
}

private class ExPlatServiceMock: ExPlatService {
    var returnAssignments = true

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
                ttl: 60,
                variations: [
                    "experiment": "control",
                    "another_experiment": "treatment",
                    "expired_experiment": nil
                ]
            )
        )
    }
}
