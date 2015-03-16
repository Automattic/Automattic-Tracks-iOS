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
    }
    return self;
}

- (NSDictionary *)dictionaryRepresentation
{
    NSString *uuid = [[NSUUID UUID] UUIDString];
    uuid = [uuid stringByReplacingOccurrencesOfString:@"-" withString:@""];
    
    NSDictionary *dict = @{EVENT_NAME_KEY : self.eventName,
                           USER_AGENT_NAME_KEY : @"WPiOS",
                           TIMESTAMP_KEY : @(lround(self.date.timeIntervalSince1970 * 1000)),
                           USER_TYPE_KEY : USER_TYPE_ANON,
                           USER_ID_ANON : uuid};
    return dict;
}

@end
