#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

@interface TracksContextManager : NSObject

@property (nonnull, nonatomic, strong) NSManagedObjectContext *managedObjectContext;
@property (nonnull, nonatomic, strong) NSManagedObjectModel *managedObjectModel;
@property (nonnull, nonatomic, strong) NSPersistentStoreCoordinator *persistentStoreCoordinator;

@end
