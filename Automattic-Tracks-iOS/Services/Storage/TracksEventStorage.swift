import Foundation
import CoreData
import Combine

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#elseif os(macOS)
import Cocoa
#endif

@available(iOS 13.0, OSX 10.15, *)
public class TracksEventStorage: NSObject, ObservableObject {

    public var allEvents = [ImmutableTracksEvent]()
    public var allEventsCount: Int = 0

    private let allEventsController: NSFetchedResultsController<TracksEventCoreData>

    public init(tracksContextManager: TracksContextManager) throws {

        allEventsController = NSFetchedResultsController(
            fetchRequest: TracksEventCoreData.allObjectsFetchRequest,
            managedObjectContext: tracksContextManager.managedObjectContext,
            sectionNameKeyPath: nil,
            cacheName: nil
        )

        super.init()

        allEventsController.delegate = self

        try allEventsController.performFetch()
    }
}

@available(iOS 13.0, OSX 10.15, *)
extension TracksEventStorage: NSFetchedResultsControllerDelegate {
    public func controller(_ controller: NSFetchedResultsController<NSFetchRequestResult>, didChangeContentWith snapshot: NSDiffableDataSourceSnapshotReference) {
        guard let events = controller.fetchedObjects as? [TracksEventCoreData] else {
            return
        }

        self.objectWillChange.send()

        self.allEvents = events.compactMap(ImmutableTracksEvent.init)
        self.allEventsCount = events.count
    }
}

@available(iOS 13.0, OSX 10.15, *)
extension TracksEventCoreData {
    static var allObjectsFetchRequest: NSFetchRequest<TracksEventCoreData> {
        let request: NSFetchRequest<TracksEventCoreData> = TracksEventCoreData.fetchRequest() as! NSFetchRequest<TracksEventCoreData>
        request.sortDescriptors = [
            NSSortDescriptor(key: "date", ascending: false)
        ]
        return request
    }
}
