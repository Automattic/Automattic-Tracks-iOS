#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

typedef NS_ENUM(NSUInteger, TracksEventUserType) {
    TracksEventUserTypeAnonymous,
    TracksEventUserTypeWordPressCom,
};

@interface TracksEvent : NSManagedObject

@property (nonatomic, copy) NSString *eventName;
@property (nonatomic, copy) NSDate *date;
@property (nonatomic, copy) NSString *user;
@property (nonatomic, copy) NSString *userAgent;
@property (nonatomic, assign) TracksEventUserType userType;

@property (nonatomic, readonly) NSDictionary *dictionaryRepresentation;

@end
