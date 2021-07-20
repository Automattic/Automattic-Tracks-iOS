#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>


@interface TracksEventCoreData : NSManagedObject

@property (nonatomic, retain) NSDate * date;
@property (nonatomic, retain) NSString *eventName;
@property (nonatomic, retain) NSString *username;
@property (nonatomic, retain) NSString *userAgent;
@property (nonatomic, retain) NSString *userID;
@property (nonatomic, retain) NSNumber *userType;
@property (nonatomic, retain) NSString *uuid;
@property (nonatomic, retain) NSNumber *retryCount;
@property (nonatomic, retain) NSDictionary *userProperties;
@property (nonatomic, retain) NSDictionary *deviceInfo;
@property (nonatomic, retain) NSDictionary *customProperties;

@end
