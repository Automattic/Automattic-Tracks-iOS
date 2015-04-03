#import <Foundation/Foundation.h>
#import "TracksEvent.h"
#import "TracksContextManager.h"

@interface TracksEventService : NSObject

- (instancetype)initWithContextManager:(TracksContextManager *)contextManager;

- (TracksEvent *)createTracksEventWithName:(NSString *)name;

- (TracksEvent *)createTracksEventWithName:(NSString *)name
                                  username:(NSString *)username
                                 userAgent:(NSString *)userAgent
                                  userType:(TracksEventUserType)userType
                                 eventDate:(NSDate *)date;

- (TracksEvent *)createTracksEventForAliasingWordPressComUser:(NSString *)username
                                        withAnonymousUsername:(NSString *)anonymousUsername;

- (NSArray *)allTracksEvents;

- (NSUInteger)numberOfTracksEvents;

- (void)removeTracksEvents:(NSArray *)tracksEvents;

@end
