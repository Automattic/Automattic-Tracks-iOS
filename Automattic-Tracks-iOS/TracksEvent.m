#import "TracksEvent.h"

@implementation TracksEvent

- (instancetype)init
{
    self = [super init];
    if (self) {
        _date = [NSDate date];
        _uuid = [NSUUID UUID];
        _customProperties = [NSMutableDictionary new];
        _deviceProperties = [NSMutableDictionary new];
        _userProperties = [NSMutableDictionary new];
    }
    return self;
}

@end
