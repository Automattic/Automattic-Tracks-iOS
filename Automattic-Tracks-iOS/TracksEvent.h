#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TracksEventUserType) {
    TracksEventUserTypeAnonymous,
    TracksEventUserTypeWordPressCom,
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

@end
