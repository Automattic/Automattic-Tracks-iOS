#import "TracksEvent.h"

static NSString *const EVENT_NAME_KEY = @"_en";
static NSString *const USER_AGENT_NAME_KEY = @"_via_ua";
static NSString *const TIMESTAMP_KEY = @"_ts";
static NSString *const USER_TYPE_KEY = @"_ut";
static NSString *const USER_TYPE_ANON = @"anon";
static NSString *const USER_ID_ANON = @"anonId";
static NSString *const USER_ID_KEY = @"_ui";
static NSString *const USER_LOGIN_NAME_KEY = @"_ul";

@implementation TracksEvent

- (instancetype)init
{
    self = [super init];
    if (self) {
        _date = [NSDate date];
        _uuid = [NSUUID UUID];
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    uuid = [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSMutableDictionary *dict = [NSMutableDictionary new];
    dict[EVENT_NAME_KEY] = self.eventName;
    dict[USER_AGENT_NAME_KEY] = @"WPiOS";
    dict[TIMESTAMP_KEY] = @(lround(self.date.timeIntervalSince1970 * 1000));
    dict[USER_ID_ANON] = uuid;
    
    if (self.userType == TracksEventUserTypeAnonymous) {
        dict[USER_TYPE_KEY] = USER_TYPE_ANON;
    }
    
    return dict;
}

@end
