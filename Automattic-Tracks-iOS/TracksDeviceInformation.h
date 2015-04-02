#import <UIKit/UIKit.h>

@interface TracksDeviceInformation : NSObject

@property (nonatomic, readonly) NSString *os;
@property (nonatomic, readonly) NSString *version;
@property (nonatomic, readonly) NSString *manufacturer;
@property (nonatomic, readonly) NSString *brand;
@property (nonatomic, readonly) NSString *model;

@property (nonatomic, readonly) NSString *appName;
@property (nonatomic, readonly) NSString *appVersion;
@property (nonatomic, readonly) NSString *appBuild;

@property (nonatomic, readonly) NSString *deviceLanguage;
//@property (nonatomic, readonly) BOOL hasNFC;
//@property (nonatomic, readonly) BOOL isTelephone;
//@property (nonatomic, readonly) NSString *displayMetrics;

/*
 mImmutableDeviceInfoJSON.put("has_NFC", hasNFC());
 mImmutableDeviceInfoJSON.put("has_telephony", hasTelephony());
 mImmutableDeviceInfoJSON.put("display_density_dpi", dMetrics.densityDpi);
 mImmutableDeviceInfoJSON.put("bluetooth_version", getBluetoothVersion());

 mutable
 mutableDeviceInfo.put("bluetooth_enabled", isBluetoothEnabled());
 mutableDeviceInfo.put("current_network_operator", getCurrentNetworkOperator());
 mutableDeviceInfo.put("phone_radio_type", getPhoneRadioType()); // NONE - GMS - CDMA - SIP
 mutableDeviceInfo.put("wifi_connected", isWifiConnected());

 */

@end
