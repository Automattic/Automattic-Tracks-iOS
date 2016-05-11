#import "TracksEventPersistenceService.h"
#import "TracksEventCoreData.h"
#import "TracksLoggingPrivate.h"

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
    __block NSMutableArray *transformedResults;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TracksEvent"];
        
        NSError *error;
        NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
        
        if (error) {
            DDLogError(@"Error while fetching all TracksEvent: %@", error);
            return;
        }
        
        transformedResults = [[NSMutableArray alloc] initWithCapacity:results.count];
        for (TracksEventCoreData *eventCoreData in results) {
            TracksEvent *tracksEvent = [self mapToTracksEventWithTracksEventCoreData:eventCoreData];
            [transformedResults addObject:tracksEvent];
        }
    }];
    
    return transformedResults;
}


- (NSUInteger)countAllTracksEvents
{
    __block NSUInteger count = 0;
    
    [self.managedObjectContext performBlockAndWait:^{
        NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TracksEvent"];
        
        NSError *error;
        count = [self.managedObjectContext countForFetchRequest:fetchRequest error:&error];
        
        if (error) {
            DDLogError(@"Error while fetching count of TracksEvent: %@", error);
        }
    }];
    
    return count;
}


- (void)removeTracksEvents:(NSArray *)tracksEvents
{
    [self.managedObjectContext performBlockAndWait:^{
        for (TracksEvent *tracksEvent in tracksEvents) {
            TracksEventCoreData *tracksEventCoreData = [self findTracksEventCoreDataWithUUID:tracksEvent.uuid];
            
            if (tracksEventCoreData) {
                [self.managedObjectContext deleteObject:tracksEventCoreData];
            } else {
                DDLogWarn(@"No TracksEventCoreData instance found with UUID: %@", tracksEvent.uuid);
            }
        }
        
        [self saveManagedObjectContext];
    }];
}


- (void)incrementRetryCountForEvents:(NSArray *)tracksEvents
{
    [self.managedObjectContext performBlockAndWait:^{
        for (TracksEvent *tracksEvent in tracksEvents) {
            TracksEventCoreData *tracksEventCoreData = [self findTracksEventCoreDataWithUUID:tracksEvent.uuid];
            
            tracksEventCoreData.retryCount = @(tracksEventCoreData.retryCount.integerValue + 1);
        }
        
        [self saveManagedObjectContext];
    }];
}


#pragma mark - Private methods

- (TracksEventCoreData *)findTracksEventCoreDataWithUUID:(NSUUID *)uuid
{
    NSFetchRequest *fetchRequest = [NSFetchRequest fetchRequestWithEntityName:@"TracksEvent"];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"uuid == %@", [uuid UUIDString]];
    fetchRequest.predicate = predicate;
    
    NSError *error;
    NSArray *results = [self.managedObjectContext executeFetchRequest:fetchRequest error:&error];
    
    if (error) {
        DDLogError(@"Error while fetching TracksEvent by UUID: %@", error);
        return nil;
    }
    
    return results.firstObject;
}

- (TracksEventCoreData *)createTracksEventCoreDataWithTracksEvent:(TracksEvent *)tracksEvent
{
    TracksEventCoreData *tracksEventCoreData = [NSEntityDescription insertNewObjectForEntityForName:@"TracksEvent" inManagedObjectContext:self.managedObjectContext];
    tracksEventCoreData.uuid = tracksEvent.uuid.UUIDString;
    tracksEventCoreData.eventName = tracksEvent.eventName;
    tracksEventCoreData.date = tracksEvent.date;
    tracksEventCoreData.username = tracksEvent.username;
    tracksEventCoreData.userAgent = tracksEvent.userAgent;
    tracksEventCoreData.userID = tracksEvent.userID;
    tracksEventCoreData.userType = @(tracksEvent.userType);
    tracksEventCoreData.customProperties = tracksEvent.customProperties;
    tracksEventCoreData.deviceInfo = tracksEvent.deviceProperties;
    tracksEventCoreData.userProperties = tracksEvent.userProperties;
    
    return tracksEventCoreData;
}

- (BOOL)saveManagedObjectContext
{
    NSError *error;
    BOOL result = [self.managedObjectContext save:&error];
    
    if (error) {
        DDLogError(@"Error while saving context: %@", error);
    }
    
    return result;
}


- (TracksEvent *)mapToTracksEventWithTracksEventCoreData:(TracksEventCoreData *)tracksEventCoreData
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.uuid = [[NSUUID alloc] initWithUUIDString:tracksEventCoreData.uuid];
    tracksEvent.eventName = tracksEventCoreData.eventName;
    tracksEvent.date = tracksEventCoreData.date;
    tracksEvent.username = tracksEventCoreData.username;
    tracksEvent.userID = tracksEventCoreData.userID;
    tracksEvent.userAgent = tracksEventCoreData.userAgent;
    tracksEvent.userType = tracksEventCoreData.userType.unsignedIntegerValue;
    [tracksEvent.customProperties addEntriesFromDictionary:tracksEventCoreData.customProperties];
    [tracksEvent.deviceProperties addEntriesFromDictionary:tracksEventCoreData.deviceInfo];
    [tracksEvent.userProperties addEntriesFromDictionary:tracksEventCoreData.userProperties];
    
    return tracksEvent;
}

@end
