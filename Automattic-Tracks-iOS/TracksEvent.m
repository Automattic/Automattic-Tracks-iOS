#import "TracksEvent.h"

NSString *const TracksEventNameKey = @"_en";
NSString *const TracksUserAgentKey = @"_via_ua";
NSString *const TracksTimestampKey = @"_ts";
NSString *const TracksUserTypeKey = @"_ut";
NSString *const TracksUserIDKey = @"_ui";
NSString *const TracksUsernameKey = @"_ul";

static NSString *const TracksUserTypeAnonymous = @"anon";
static NSString *const TracksUserTypeWPCOM = @"wpcom:user_id";
static NSString *const USER_ID_ANON = @"anonId";

@implementation TracksEvent

- (instancetype)init
{
    self = [super init];
    if (self) {
        _date = [NSDate date];
        _uuid = [NSUUID UUID];
        _customProperties = [NSMutableDictionary new];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentationWithParentCommonProperties:(NSDictionary *)parentCommonProperties
{
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[TracksEventNameKey] = self.eventName;
    dict[TracksTimestampKey] = @(lround(self.date.timeIntervalSince1970 * 1000));
    
    if (self.userType == TracksEventUserTypeAnonymous) {
        dict[TracksUserTypeKey] = TracksUserTypeAnonymous;
        dict[TracksUserIDKey] = self.userID;
    } else {
        dict[TracksUserTypeKey] = TracksUserTypeWPCOM;
        dict[TracksUserIDKey] = self.userID;
        dict[TracksUsernameKey] = self.username;
    }    

    // Only add objects that don't exist in parent or are different than parent
    for (id key in self.customProperties.keyEnumerator) {
        if (parentCommonProperties[key] != nil && parentCommonProperties[key] == self.customProperties[key]) {
            continue;
        }
        
        dict[key] = self.customProperties[key];
    }
    
    if (self.userAgent.length > 0 && ![parentCommonProperties[TracksUserAgentKey] isEqualToString:self.userAgent]) {
        dict[TracksUserAgentKey] = self.userAgent;
    }
    
    return dict;
}

@end
