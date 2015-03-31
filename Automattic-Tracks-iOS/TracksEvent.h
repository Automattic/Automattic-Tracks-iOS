#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TracksEventUserType) {
    TracksEventUserTypeAnonymous,
    TracksEventUserTypeWordPressCom,
};

@interface TracksEvent : NSObject

@property (nonatomic, strong) NSUUID *uuid;
@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, strong) NSDate *date;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, assign) TracksEventUserType userType;

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

@end
