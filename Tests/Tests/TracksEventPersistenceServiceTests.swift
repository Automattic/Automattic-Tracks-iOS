@testable import AutomatticTracks
import XCTest
import SwiftUI

class TracksEventPersistenceServiceTests: XCTestCase {
    
    // MARK: - Helper methods
    
    func createTestTracksEvent(_ uuid: UUID) -> TracksEvent {
        let event = TracksEvent()
        
        event.uuid = uuid
        event.eventName = "test_event_name"
        event.date = Date()
        event.username = "AnonymousTestUser"
        event.userID = "AnonymousTestUser"
        event.userAgent = "TestUserAgent"
        event.userType = .anonymous
        
        return event
    }
    
    func createTracksEvents(uuids: [UUID]) -> [TracksEvent] {
        uuids.map { uuid in
            createTestTracksEvent(uuid)
        }
    }
    
    func fetchTrackEventCoreData(for uuids: [UUID], context: NSManagedObjectContext, andDo completion: @escaping (Result<[TracksEventCoreData], Error>) -> Void) {
        let uuidStrings = uuids.map { $0.uuidString }
        
        context.performAndWait {
            let fetchRequest = NSFetchRequest<TracksEventCoreData>(entityName: "TracksEvent")
            fetchRequest.predicate = NSPredicate(format: "uuid in %@", uuidStrings)

            do {
                let events = try fetchRequest.execute()
                
                completion(.success(events))
            } catch {
                completion(.failure(error))
            }
        }
    }
    
    // MARK: - Tests
    
    /// Tests that persisting a tracks event works.
    ///
    func testPersistTracksEvent() {
        let contextManager = TracksTestContextManager()
        let context = contextManager.managedObjectContext
        let service = TracksEventPersistenceService(managedObjectContext: context)
        
        let uuid = UUID()
        let event = createTestTracksEvent(uuid)
        XCTAssertNoThrow(try event.validateObject())
        
        service.persistTracksEvent(event)
        
        context.performAndWait {
            let fetchRequest = NSFetchRequest<TracksEventCoreData>(entityName: "TracksEvent")
            fetchRequest.predicate = NSPredicate(format: "uuid = %@", uuid.uuidString)

            do {
                let result = try fetchRequest.execute()
                
                XCTAssertEqual(result.count, 1)
            } catch {
                XCTFail()
            }
        }
    }
    
    func testIncrementRetryCount() {
        let testCompletedExpectation = expectation(description: "The test is run completely")
        testCompletedExpectation.expectedFulfillmentCount = 1
        testCompletedExpectation.assertForOverFulfill = true
        
        let contextManager = TracksTestContextManager()
        let context = contextManager.managedObjectContext
        let service = TracksEventPersistenceService(managedObjectContext: context)
        
        let uuids = (0 ..< 2002).map { index in
            UUID()
        }
        
        let tracksEvents = createTracksEvents(uuids: uuids)
        XCTAssertEqual(tracksEvents.count, uuids.count)

        for event in tracksEvents {
            service.persistTracksEvent(event)
        }
        
        // We're adding an extra event that should not have its retry count incremented.
        let extraUUID = UUID()
        service.persistTracksEvent(createTestTracksEvent(extraUUID))
        
        // The first control includes the extra UUID because all retry counts should be zero
        fetchTrackEventCoreData(for: uuids + [extraUUID], context: context) { result in
            switch result {
            case .success(let events):
                XCTAssertEqual(tracksEvents.count + 1, events.count) // +1 for the extra event
                
                for event in events {
                    XCTAssertEqual(event.retryCount, 0)
                }
            case .failure(let error):
                XCTFail("Error: \(String(describing: error))")
            }
        }
        
        service.incrementRetryCount(forEvents: tracksEvents) { [unowned self] in
            self.fetchTrackEventCoreData(for: uuids, context: context) { result in
                switch result {
                case .success(let events):
                    XCTAssertEqual(tracksEvents.count, events.count)
                    
                    for event in events {
                        XCTAssertEqual(event.retryCount, 1)
                    }
                case .failure(let error):
                    XCTFail("Error: \(String(describing: error))")
                }
            }
            
            // Make sure our extra UUID's retry count hasn't changed
            self.fetchTrackEventCoreData(for: [extraUUID], context: context) { result in
                switch result {
                case .success(let events):
                    XCTAssertEqual(1, events.count)
                    
                    for event in events {
                        XCTAssertEqual(event.retryCount, 0)
                    }
                    
                    testCompletedExpectation.fulfill()
                case .failure(let error):
                    XCTFail("Error: \(String(describing: error))")
                }
            }
        }

        waitForExpectations(timeout: 5)
    }
}
