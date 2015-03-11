#import <Foundation/Foundation.h>

@interface TracksEvent : NSObject

@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, copy) NSString *userType;

@end
