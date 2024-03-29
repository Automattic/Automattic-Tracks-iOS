@testable import AutomatticTracks
import Foundation

fileprivate var persistentStoreExistsKey: UInt8 = 0

/// This class duplicates the class found in `TestTracksContextManager.swift`, because there's no support in
/// packages for mixed-language source files and method-calling.  We could work around this problem
/// in other ways but since this will eventually move to Swift, I may as well just duplicate it for now and we
/// can clean-up once we remove the remaining ObjC code.
///
class TracksTestContextManager: TracksContextManager {

    /// A convenience flag to know whether the persistent store has been created.  We can't use the
    /// superclass' getter because it will create a persistent store if it hasn't been created before.
    ///
    private var persistentStoreExists = false

    override var persistentStoreCoordinator: NSPersistentStoreCoordinator {
        set {
            super.persistentStoreCoordinator = newValue
        }

        get {
            NSLog("Using in-memory store")

            if persistentStoreExists {
                return super.persistentStoreCoordinator
            }

            // This is important for automatic version migration. Leave it here!
            let options = [
                NSInferMappingModelAutomaticallyOption: true,
                NSMigratePersistentStoresAutomaticallyOption: true,
            ]

            let persistentStoreCoordinator = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)

            do {
                try persistentStoreCoordinator.addPersistentStore(ofType: NSInMemoryStoreType, configurationName: nil, at: nil, options: options)
            } catch {
                NSLog("Unresolved error %@, %@", String(describing: error), (error as NSError).userInfo)
                abort()
            }

            self.persistentStoreCoordinator = persistentStoreCoordinator
            persistentStoreExists = true

            return persistentStoreCoordinator
        }
    }
}
