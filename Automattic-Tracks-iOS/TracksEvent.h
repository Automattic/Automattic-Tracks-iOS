#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TracksEventUserType) {
    TracksEventUserTypeAnonymous,
    TracksEventUserTypeWordPressCom,
};

FOUNDATION_EXPORT NSString *const TracksEventNameKey;
FOUNDATION_EXPORT NSString *const TracksUserAgentKey;
FOUNDATION_EXPORT NSString *const TracksTimestampKey;
FOUNDATION_EXPORT NSString *const TracksUserTypeKey;
FOUNDATION_EXPORT NSString *const TracksUserIDKey;
FOUNDATION_EXPORT NSString *const TracksUsernameKey;

@interface TracksEvent : NSObject

@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, assign) TracksEventUserType userType;
@property (nonatomic, readonly) NSMutableDictionary *customProperties;

- (NSDictionary *)dictionaryRepresentationWithParentCommonProperties:(NSDictionary *)parentCommonProperties;

@end
