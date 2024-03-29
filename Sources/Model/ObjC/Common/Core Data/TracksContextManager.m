#import "TracksContextManager.h"
#import "TracksLogging.h"


NSString *const TracksApplicationSupportException   = @"TracksApplicationSupportException";
NSString *const TracksPersistentStoreException      = @"TracksPersistentStoreException";

@implementation TracksContextManager

#pragma mark - Core Data stack

- (NSManagedObjectModel *)managedObjectModel {
    // The managed object model for the application. It is a fatal error for the application not to be able to find and load its model.
    if (_managedObjectModel != nil) {
        return _managedObjectModel;
    }

    /*
     tracksBundle is the "bundle" containing the DataModel.bundle:
     - If frameworks are used, it's Automattic-Tracks-iOS.framework
     - Otherwise, it's the main bundle
     */
#if SWIFT_PACKAGE
    NSBundle *bundle = SWIFTPM_MODULE_BUNDLE;
    NSURL *modelURL = [bundle URLForResource:@"Tracks" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
#else
    NSBundle *tracksBundle = [NSBundle bundleForClass:[self class]];
    NSString *path = [tracksBundle pathForResource:@"DataModel" ofType:@"bundle"];
    NSBundle *bundle = path != nil ? [NSBundle bundleWithPath:path] : [NSBundle bundleForClass:[self class]];
    NSURL *modelURL = [bundle URLForResource:@"Tracks" withExtension:@"momd"];
    _managedObjectModel = [[NSManagedObjectModel alloc] initWithContentsOfURL:modelURL];
    return _managedObjectModel;
#endif
}

- (NSPersistentStoreCoordinator *)persistentStoreCoordinator {
    // The persistent store coordinator for the application. This implementation creates and return a coordinator, having added the store for the application to it.
    if (_persistentStoreCoordinator != nil) {
        return _persistentStoreCoordinator;
    }
    
    // Create the coordinator and store
    
    _persistentStoreCoordinator = [[NSPersistentStoreCoordinator alloc] initWithManagedObjectModel:[self managedObjectModel]];
    NSURL *storeURL = [self storeURL];
    NSError *error = nil;
    if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
        
        // Delete the store and try again
        [[NSFileManager defaultManager] removeItemAtPath:storeURL.path error:nil];
        if (![_persistentStoreCoordinator addPersistentStoreWithType:NSSQLiteStoreType configuration:nil URL:storeURL options:nil error:&error]) {
            
            // This is not really an officially public way to check for prewarming, but it's the only way we have to
            // check it, and since this information is extremely important for being able to debug issues here
            // it's worth including it.  Worst case scenario this could cease working, but should not cause any issues
            // whatsoever.
            NSString *prewarming = [NSProcessInfo processInfo].environment[@"ActivePrewarm"] ?: @"0";
            
            // Replace this with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            TracksLogError(@"Unresolved error %@, %@. Context info {prewarming=%@, storeURL=%@}.", error, [error userInfo], prewarming, storeURL);
            
            @throw [NSException exceptionWithName:TracksPersistentStoreException
                                           reason:[NSString stringWithFormat:@"Error initializing Tracks: %@", error]
                                         userInfo:error.userInfo];
        }
    }
    
    return _persistentStoreCoordinator;
}

- (NSURL *)storeURL {
    return [[self storeContainerDirectoryURL] URLByAppendingPathComponent:@"Tracks.sqlite"];
}

- (NSURL *)storeContainerDirectoryURL {
    return [self applicationSupportURLForContainerApp];
}

- (NSURL *)applicationSupportURLForContainerApp {
    // The container app is the one owning the main bundle
    return [self applicationSupportURLForAppWithBundleIdentifier:[[NSBundle mainBundle] bundleIdentifier]];
}

- (NSURL *)applicationSupportURLForAppWithBundleIdentifier:(NSString *)bundleIdentifier {
    NSURL *folder = [[self applicationSupportURL] URLByAppendingPathComponent:bundleIdentifier];
    NSError *error = nil;
    [[NSFileManager defaultManager] createDirectoryAtURL:folder
                             withIntermediateDirectories:true
                                              attributes:nil
                                                   error:&error];
    
    // It seems safe not to handle this error because Application Support should always be
    // available and one should always be able to create a folder in it
    if (error != nil) {
        TracksLogError(@"Failed to create folder for %@ in Application Support: %@, %@", bundleIdentifier, error, [error userInfo]);
        
        @throw [NSException exceptionWithName:TracksApplicationSupportException
                                       reason:[NSString stringWithFormat:@"Error creating the ApplicationSupport Folder: %@", error]
                                     userInfo:error.userInfo];
        
    }
    
    return folder;
}

// Application Support contains "the files that your app creates and manages on behalf of the user
// and can include files that contain user data".
//
// See:
// https://developer.apple.com/library/archive/documentation/FileManagement/Conceptual/FileSystemProgrammingGuide/MacOSXDirectories/MacOSXDirectories.html#//apple_ref/doc/uid/TP40010672-CH10-SW1
- (NSURL *)applicationSupportURL {
    // Application Support should always be available, so no checking whether the array is empty
    return [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory
                                                   inDomains:NSUserDomainMask] lastObject];
}

- (NSManagedObjectContext *)managedObjectContext {
    // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.)
    if (_managedObjectContext != nil) {
        return _managedObjectContext;
    }
    
    NSPersistentStoreCoordinator *coordinator = [self persistentStoreCoordinator];
    if (!coordinator) {
        return nil;
    }
    _managedObjectContext = [[NSManagedObjectContext alloc] initWithConcurrencyType:NSPrivateQueueConcurrencyType];
    [_managedObjectContext setPersistentStoreCoordinator:coordinator];
    return _managedObjectContext;
}

#pragma mark - Core Data Saving support

- (void)saveContext {
    NSManagedObjectContext *managedObjectContext = self.managedObjectContext;
    if (managedObjectContext != nil) {
        NSError *error = nil;
        if ([managedObjectContext hasChanges] && ![managedObjectContext save:&error]) {
            // Replace this implementation with code to handle the error appropriately.
            // abort() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
            TracksLogError(@"Unresolved error %@, %@", error, [error userInfo]);
            abort();
        }
    }
}

@end
