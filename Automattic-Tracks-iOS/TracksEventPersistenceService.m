#import "TracksEventPersistenceService.h"
#import "TracksEventCoreData.h"

@interface TracksEventPersistenceService ()

@property (nonatomic, strong) NSManagedObjectContext *managedObjectContext;

@end

@implementation TracksEventPersistenceService

- (instancetype)initWithManagedObjectContext:(NSManagedObjectContext *)managedObjectContext
{
    self = [self init];
    if (self) {
        _managedObjectContext = managedObjectContext;
    }
    return self;
}


- (void)persistTracksEvent:(TracksEvent *)tracksEvent
{
    [self.managedObjectContext performBlockAndWait:^{
        [self createTracksEventCoreDataWithTracksEvent:tracksEvent];
        
        [self saveManagedObjectContext];
    }];
}


- (NSArray *)fetchAllTracksEvents
{
    return nil;
}


- (NSUInteger)countAllTracksEvents
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TracksEvent"];
    
    NSError *error;
    NSUInteger count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Error while fetching count of TracksEvent: %@", error);
    }
    
    return count;
}


- (TracksEventCoreData *)findTracksEventCoreDataWithUUID:(NSUUID *)uuid
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TracksEvent"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid == %@", [uuid UUIDString]];
    fetchRequest.predicate = predicate;
    
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        NSLog(@"Error while fetching TracksEvent by UUID: %@", error);
        return nil;
    }
    
    return results.firstObject;
}

- (TracksEventCoreData *)createTracksEventCoreDataWithTracksEvent:(TracksEvent *)tracksEvent
{
    TracksEventCoreData *tracksEventCoreData = [NSEntityDescription insertNewObjectForEntityForName:@"TracksEvent" inManagedObjectContext:self.managedObjectContext];
    tracksEventCoreData.eventName = tracksEvent.eventName;
    tracksEventCoreData.date = tracksEvent.date;
    tracksEventCoreData.user = tracksEvent.user;
    tracksEventCoreData.userAgent = tracksEvent.userAgent;
    tracksEventCoreData.userType = @(tracksEvent.userType);
    
    return tracksEventCoreData;
}

- (BOOL)saveManagedObjectContext
{
    NSError *error;
    BOOL result = [self.managedObjectContext save:&error];
    
    if (error) {
        NSLog(@"Error while saving context: %@", error);
    }
    
    return result;
}

@end
