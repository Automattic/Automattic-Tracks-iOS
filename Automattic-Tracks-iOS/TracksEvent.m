#import "TracksEvent.h"

static NSString *const TracksEventNameKey = @"_en";
static NSString *const USER_AGENT_NAME_KEY = @"_via_ua";
static NSString *const TIMESTAMP_KEY = @"_ts";
static NSString *const TracksUserTypeKey = @"_ut";
static NSString *const TracksUserIDKey = @"_ui";
static NSString *const TracksUsernameKey = @"_ul";

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
    dict[TIMESTAMP_KEY] = @(lround(self.date.timeIntervalSince1970 * 1000));
//    dict[USER_ID_ANON] = uuid;
    
    if (self.userType == TracksEventUserTypeAnonymous) {
        dict[TracksUserTypeKey] = TracksUserTypeAnonymous;
        dict[TracksUserIDKey] = TracksUserTypeAnonymous;
    } else {
        dict[TracksUserTypeKey] = TracksUserTypeWPCOM;
        dict[TracksUserIDKey] = @""; // TODO
        dict[TracksUsernameKey] = self.user;
    }
    
    

    // Only add objects that don't exist in parent or are different than parent
    for (id key in self.customProperties.keyEnumerator) {
        if (parentCommonProperties[key] != nil && parentCommonProperties[key] == self.customProperties[key]) {
            continue;
        }
        
        dict[key] = self.customProperties[key];
    }
    
    if (self.userAgent.length > 0 && ![parentCommonProperties[USER_AGENT_NAME_KEY] isEqualToString:self.userAgent]) {
        dict[USER_AGENT_NAME_KEY] = self.userAgent;
    }
    
    return dict;
}

@end
