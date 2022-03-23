#if SWIFT_PACKAGE
import AutomatticTracksModel
import AutomatticTracksModelObjC
#endif
import CoreData

/// Should eventually replace objC class `TracksEventPersistenceService`.  Unfortunately
/// Swift Packages do not support mixed source classes so we'll instead need to compose.
///
@objc
public class TracksEventPersistenceServiceSwift: NSObject {

    private static let incrementRetryCountBatchSize = 500
    private let managedObjectContext: NSManagedObjectContext

    @objc
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext

        super.init()
    }

    /// Increments the retry count for the specified events in batches of
    @objc
    public func incrementRetryCountForEvents(_ tracksEvents: [TracksEvent], onComplete completion: (() -> Void)?) {
        let uuidStrings = tracksEvents.map { event in
            event.uuid.uuidString
        }

        managedObjectContext.perform {
            for startIndex in stride(from: 0, to: uuidStrings.count, by: Self.incrementRetryCountBatchSize) {

                let isLastBatch = startIndex + Self.incrementRetryCountBatchSize >= uuidStrings.count
                let results: [TracksEventCoreData]
                let count = min(uuidStrings.count - startIndex, Self.incrementRetryCountBatchSize)
                let uuidStringsBatch = Array(uuidStrings[startIndex ..< startIndex + count])

                do {
                    results = try self.findCoreDataEvents(uuidStrings: uuidStringsBatch)
                } catch {
                    TracksLogError("Error while finding track events: \(String(describing: error))")

                    if isLastBatch {
                        completion?()
                    }

                    return
                }

                if results.count != count {
                    TracksLogError("Not all provided events were found in the persistence layer. This signals a possible logical error in the tracking, persistence and retry-count-incrementing code.  Please review.")
                }

                for event in results {
                    event.retryCount = event.retryCount.intValue + 1 as NSNumber
                }

                self.saveManagedObjectContext()

                if isLastBatch {
                    completion?()
                }
            }
        }
    }

    func findCoreDataEvents(uuidStrings: [String]) throws -> [TracksEventCoreData] {
        let fetchRequest = NSFetchRequest<TracksEventCoreData>(entityName: "TracksEvent")
        fetchRequest.predicate = NSPredicate(format: "uuid in %@", uuidStrings)

        return try fetchRequest.execute()
    }

    func saveManagedObjectContext() {
        do {
            try managedObjectContext.save()
        } catch {
            TracksLogError("Error while saving context: \(String(describing: error))")
        }
    }
}
