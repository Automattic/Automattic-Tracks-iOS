#import "TracksEventService.h"
#import "TracksEventPersistenceService.h"

@interface TracksEventService ()

@property (nonatomic, strong) TracksContextManager *contextManager;
@property (nonatomic, strong) TracksEventPersistenceService *persistenceService;

@end

@implementation TracksEventService

- (instancetype)initWithContextManager:(TracksContextManager *)contextManager
{
    self = [self init];
    
    if (self) {
        _contextManager = contextManager;
        _persistenceService = [[TracksEventPersistenceService alloc] initWithManagedObjectContext:contextManager.managedObjectContext];
    }
    
    return self;
}


- (TracksEvent *)createTracksEventWithName:(NSString *)name
{
    return [self createTracksEventWithName:name username:nil userAgent:nil userType:TracksEventUserTypeAnonymous eventDate:[NSDate date]];
}


- (TracksEvent *)createTracksEventWithName:(NSString *)name
                                  username:(NSString *)username
                                 userAgent:(NSString *)userAgent
                                  userType:(TracksEventUserType)userType
                                 eventDate:(NSDate *)date
{
    NSParameterAssert(name.length > 0);
    
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.uuid = [NSUUID UUID];
    tracksEvent.eventName = name;
    tracksEvent.user = username;
    tracksEvent.userAgent = userAgent;
    tracksEvent.userType = userType;
    tracksEvent.date = date;
    
    [self.persistenceService persistTracksEvent:tracksEvent];
    
    return tracksEvent;
}

- (NSUInteger)numberOfTracksEvents
{
    return [self.persistenceService countAllTracksEvents];
}


- (NSArray *)allTracksEvents
{
    return nil;
}


- (void)removeTracksEvents:(NSArray *)tracksEvents
{
    
}


@end
