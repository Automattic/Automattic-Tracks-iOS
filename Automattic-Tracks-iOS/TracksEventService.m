#import "TracksEventService.h"
#import "TracksEventPersistenceService.h"
#import "TracksLoggingPrivate.h"

@interface TracksEventService ()

@property (nonatomic, strong) TracksContextManager *contextManager;

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
                          customProperties:(NSDictionary *)customProperties
                          deviceProperties:(NSDictionary *)deviceProperties
                            userProperties:(NSDictionary *)userProperties
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
    [tracksEvent.customProperties addEntriesFromDictionary:customProperties];
    [tracksEvent.deviceProperties addEntriesFromDictionary:deviceProperties];
    [tracksEvent.userProperties addEntriesFromDictionary:userProperties];

    NSError *error;
    BOOL isValid = [tracksEvent validateObject:&error];
    if (!isValid) {
        DDLogWarn(@"Error when validating TracksEvent: %@", error);
        return nil;
    }
    
    [self.persistenceService persistTracksEvent:tracksEvent];
    
    return tracksEvent;
}


- (TracksEvent *)createTracksEventForAliasingWordPressComUser:(NSString *)username
                                                       userID:(NSString *)userID
                                          withAnonymousUserID:(NSString *)anonymousUserID
{
    TracksEvent *tracksEvent = [TracksEvent new];
    tracksEvent.eventName = @"_aliasUser";
    tracksEvent.customProperties[@"anonId"] = anonymousUserID;
    tracksEvent.username = username;
    tracksEvent.userID = userID;
    tracksEvent.userType = TracksEventUserTypeAuthenticated;
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


- (void)incrementRetryCountForEvents:(NSArray *)tracksEvents
{
    [self.persistenceService incrementRetryCountForEvents:tracksEvents];
}


@end
