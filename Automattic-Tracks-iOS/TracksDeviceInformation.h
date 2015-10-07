#import <Foundation/Foundation.h>

@interface TracksDeviceInformation : NSObject

@property (nonatomic, readonly) NSString *os;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *manufacturer;
@property (nonatomic, readonly) NSString *brand;
@property (nonatomic, readonly) NSString *model;

@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSString *appBuild;

// This information has the tendency to change
@property (nonatomic, readonly) NSString *deviceLanguage;
@property (nonatomic, readonly) NSString *currentNetworkOperator;
@property (nonatomic, readonly) NSString *currentNetworkRadioType;
@property (nonatomic, assign) BOOL isWiFiConnected;

@end
