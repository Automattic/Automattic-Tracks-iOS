#if SWIFT_PACKAGE
import AutomatticTracksModel
import AutomatticTracksModelObjC
#endif
import CoreData

/// Should eventually replace objC class `TracksEventPersistenceService`.  Unfortunately
/// Swift Packages do not support mixed source classes so we'll instead need to compose.
///
/// The naming is slightly different with "Track" instead of "Tracks", but the class is internal for now so it
/// should be fairly acceptable to do this.
///
@objc
public class TrackEventPersistenceService: NSObject {
    
    private let managedObjectContext: NSManagedObjectContext
    
    @objc
    public init(managedObjectContext: NSManagedObjectContext) {
        self.managedObjectContext = managedObjectContext
        
        super.init()
    }
    
    /// Increments the retry count for the specified events in batches of
    @objc
    public func incrementRetryCountForEvents(_ tracksEvents: [TracksEvent], onComplete completion: ((Error?) -> Void)?) {
        let uuidStrings = tracksEvents.map { event in
            event.uuid.uuidString
        }
        
        let batchSize = 500
        
        for startIndex in stride(from: 0, to: uuidStrings.count, by: batchSize) {
            let isLastBatch = startIndex + batchSize >= uuidStrings.count
            
            managedObjectContext.perform {
                let results: [TracksEventCoreData]
                let count = min(uuidStrings.count - startIndex, batchSize)
                let uuidStringsBatch = Array(uuidStrings[startIndex ..< startIndex + count])
                
                do {
                    results = try self.findTrackEventCoreData(uuidStrings: uuidStringsBatch)
                } catch {
                    TracksLogError("Error while finding track events: \(String(describing: error))")
                    
                    if isLastBatch {
                        completion?(error)
                    }
                    
                    return
                }
                
                for event in results {
                    event.retryCount = event.retryCount.intValue + 1 as NSNumber
                }
                
                self.saveManagedObjectContext()
                
                if isLastBatch {
                    completion?(nil)
                }
            }
        }
    }
    
    func findTrackEventCoreData(uuidStrings: [String]) throws -> [TracksEventCoreData] {
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
