#import <Foundation/Foundation.h>
#import "TracksEvent.h"
#import "TracksContextManager.h"

@class TracksEventPersistenceService;

@interface TracksEventService : NSObject

@property (nonatomic, strong) TracksEventPersistenceService *persistenceService;

- (instancetype)initWithContextManager:(TracksContextManager *)contextManager;

- (TracksEvent *)createTracksEventWithName:(NSString *)name
                                  username:(NSString *)username
                                    userID:(NSString *)userID
                                 userAgent:(NSString *)userAgent
                                  userType:(TracksEventUserType)userType
                                 eventDate:(NSDate *)date
                          customProperties:(NSDictionary *)customProperties
                          deviceProperties:(NSDictionary *)deviceProperties
                            userProperties:(NSDictionary *)userProperties;

- (TracksEvent *)createTracksEventForAliasingWordPressComUser:(NSString *)username
                                                       userID:(NSString *)userID
                                          withAnonymousUserID:(NSString *)anonymousUserID;

- (NSArray *)allTracksEvents;

- (NSUInteger)numberOfTracksEvents;

- (void)removeTracksEvents:(NSArray *)tracksEvents;

- (void)incrementRetryCountForEvents:(NSArray *)tracksEvents;

@end
