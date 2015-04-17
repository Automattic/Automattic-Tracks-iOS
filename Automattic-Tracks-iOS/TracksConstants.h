#import <Foundation/Foundation.h>

FOUNDATION_EXPORT NSString *const TracksErrorDomain;

typedef NS_ENUM(NSInteger, TracksErrorCode) {
    TracksErrorCodeValidationEventNameMissing,
    TracksErrorCodeValidationEventNameDashes,
    TracksErrorCodeValidationEventNameWhitespace,
    TracksErrorCodeValidationEventNamePatternMismatch,
    TracksErrorCodeValidationCustomPropertiesKeyType,
    TracksErrorCodeValidationCustomPropertiesKeyFormat,
    TracksErrorCodeValidationUserPropertiesKeyType,
    TracksErrorCodeValidationUserPropertiesKeyFormat,
    TracksErrorCodeValidationDevicePropertiesKeyType,
    TracksErrorCodeValidationDevicePropertiesKeyFormat,
};
