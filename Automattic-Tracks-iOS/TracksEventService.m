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
                                  username:(NSString *)username
                                    userID:(NSString *)userID
                                 userAgent:(NSString *)userAgent
                                  userType:(TracksEventUserType)userType
                                 eventDate:(NSDate *)date
{
    if (name == nil) {
        return nil;
    }
    
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.uuid = [NSUUID UUID];
    tracksEvent.eventName = name;
    tracksEvent.username = username;
    tracksEvent.userAgent = userAgent;
    tracksEvent.userID = userID;
    tracksEvent.userType = userType;
    tracksEvent.date = date;
    
    [self.persistenceService persistTracksEvent:tracksEvent];
    
    return tracksEvent;
}


- (TracksEvent *)createTracksEventForAliasingWordPressComUser:(NSString *)username
                                                       userID:(NSString *)userID
                                        withAnonymousUsername:(NSString *)anonymousUsername
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"_aliasUser";
    tracksEvent.customProperties[@"anonId"] = anonymousUsername;
    tracksEvent.username = username;
    tracksEvent.userID = userID;
    tracksEvent.userType = TracksEventUserTypeWordPressCom;
    tracksEvent.date = [NSDate date];
    
    [self.persistenceService persistTracksEvent:tracksEvent];
    
    return tracksEvent;
}


- (NSUInteger)numberOfTracksEvents
{
    return [self.persistenceService countAllTracksEvents];
}


- (NSArray *)allTracksEvents
{
    return [self.persistenceService fetchAllTracksEvents];
}


- (void)removeTracksEvents:(NSArray *)tracksEvents
{
    [self.persistenceService removeTracksEvents:tracksEvents];
}


@end
