#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TracksContextManager : NSObject

@property (nonnull, nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonnull, nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonnull, nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

/// In version 0.5.1 and earlier, the CoreData store was always saved in the Documents folder.
///
/// This approach is fine for sandboxed applications distributed via the Mac App Store, but would
/// result in the user being asked for access to the `~/Documents` folder in non-sandboxed apps.
///
/// To avoid this bad UX – which also blocks tests in CI with the same alert – when the app is
/// sandboxed, we can save the store in `~/Application Support`.
///
/// This designated initializer allows consumers to tell `TracksContextManager` the mode in which
/// the app is running and where to save the store.
///
/// The `super` `init` method defaults to `true` for backward compatibility.
- (nonnull instancetype)initWithSandboxedMode:(BOOL)sandboxed NS_DESIGNATED_INITIALIZER;

@end
