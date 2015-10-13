#import <Foundation/Foundation.h>
#import "TracksConstants.h"

typedef NS_ENUM(NSUInteger, TracksEventUserType) {
    TracksEventUserTypeAnonymous,
    TracksEventUserTypeAuthenticated,
};

@interface TracksEvent : NSObject

@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, copy) NSString *username;
@property (nonatomic, copy) NSString *userID;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, assign) TracksEventUserType userType;
@property (nonatomic, readonly) NSMutableDictionary *customProperties;
@property (nonatomic, readonly) NSMutableDictionary *deviceProperties;
@property (nonatomic, readonly) NSMutableDictionary *userProperties;


- (BOOL)validateObject:(NSError **)error;

@end
