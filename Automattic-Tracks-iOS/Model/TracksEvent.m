#import "TracksEvent.h"

@implementation TracksEvent

NSString *const TracksEventNameRegExPattern = @"^(([a-z0-9]+)_){2}([a-z0-9_]+)$";
NSString *const TracksPropertiesKeyRegExPattern = @"^[a-z][a-z0-9_]*$";

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


- (BOOL)validateObject:(NSError *__autoreleasing *)error
{
    NSString *eventName = self.eventName;
    NSDictionary *customProperties = self.customProperties;
    NSDictionary *deviceProperties = self.deviceProperties;
    NSDictionary *userProperties = self.userProperties;
    
    BOOL nameValid = [self validateValue:&eventName forKey:@"eventName" error:error];
    if (!nameValid) {
        return NO;
    }
    
    BOOL customPropertiesValid = [self validateValue:&customProperties forKey:@"customProperties" error:error];
    if (!customPropertiesValid) {
        return NO;
    }
    
    BOOL devicePropertiesValid = [self validateValue:&deviceProperties forKey:@"deviceProperties" error:error];
    if (!devicePropertiesValid) {
        return NO;
    }
    
    BOOL userPropertiesValid = [self validateValue:&userProperties forKey:@"userProperties" error:error];
    if (!userPropertiesValid) {
        return NO;
    }
    
    return YES;
}

#pragma mark - NSKeyValueCoding methods

- (BOOL)validateEventName:(id *)ioValue error:(NSError * __autoreleasing *)outError
{
    if (ioValue == nil || ([(NSString *)*ioValue length] < 1)) {
        if (outError != NULL) {
            NSString *errorString = NSLocalizedString(@"An event name must be at least one character.",
                                                      @"validation: TracksEvent, too short eventName error");
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                   code:TracksErrorCodeValidationEventNameMissing
                                               userInfo:userInfoDict];
        }
        
        return NO;
    } else if ([(NSString *)*ioValue rangeOfString:@"-"].location != NSNotFound) {
        if (outError != NULL) {
            NSString *errorString = NSLocalizedString(@"An event name must not contain dashes.",
                                                      @"validation: TracksEvent, contains dashes eventName error");
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                   code:TracksErrorCodeValidationEventNameDashes
                                               userInfo:userInfoDict];
        }
        
        return NO;
    } else if ([(NSString *)*ioValue rangeOfCharacterFromSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]].location != NSNotFound) {
        if (outError != NULL) {
            NSString *errorString = NSLocalizedString(@"An event name must not contain whitespace.",
                                                      @"validation: TracksEvent, whitespace eventName error");
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                   code:TracksErrorCodeValidationEventNameWhitespace
                                               userInfo:userInfoDict];
        }
        
        return NO;
    } else {
        NSString *value = (NSString *)*ioValue;
        NSError *error;
        NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:TracksEventNameRegExPattern options:0 error:&error];
        NSArray *matches = [regex matchesInString:value options:0 range:NSMakeRange(0, value.length)];
        
        if (matches.count == 0) {
            if (outError != NULL) {
                NSString *errorString = NSLocalizedString(@"An event name contain alpha characters and underscores only.",
                                                          @"validation: TracksEvent, pattern eventName error");
                NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
                *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                       code:TracksErrorCodeValidationEventNamePatternMismatch
                                                   userInfo:userInfoDict];
            }
            
            return NO;
        }
    }
    
    return YES;
}

- (BOOL)validateDate:(id *)ioValue error:(NSError * __autoreleasing *)outError
{
    if (ioValue == nil) {
        if (outError != NULL) {
            NSString *errorString = NSLocalizedString(@"An event name must be at least one character.",
                                                      @"validation: TracksEvent, too short eventName error");
            NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
            *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                   code:TracksErrorCodeValidationEventNameMissing
                                               userInfo:userInfoDict];
        }
        return NO;
    }

    return YES;
}

- (BOOL)validateCustomProperties:(id *)ioValue error:(NSError * __autoreleasing *)outError
{
    if (([(NSDictionary *)*ioValue count] > 0)) {
        NSDictionary *dict = (NSDictionary *)*ioValue;
        
        for (id key in dict.keyEnumerator) {
            if ([key isKindOfClass:[NSString class]] == NO) {
                if (outError != NULL) {
                    NSString *errorString = NSLocalizedString(@"Custom properties dictionary keys must be NSString instances.",
                                                              @"validation: TracksEvent, key type customProperties error");
                    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
                    *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                           code:TracksErrorCodeValidationCustomPropertiesKeyType
                                                       userInfo:userInfoDict];
                }
                
                return NO;
            }
            
            if ([self validPropertyName:key] == NO) {
                if (outError != NULL) {
                    NSString *errorString = NSLocalizedString(@"Custom properties dictionary keys must contain alpha characters and underscores only.",
                                                              @"validation: TracksEvent, key format customProperties error");
                    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
                    *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                           code:TracksErrorCodeValidationCustomPropertiesKeyFormat
                                                       userInfo:userInfoDict];
                }
                
                return NO;
            }
        }
        
        return YES;
    }
    
    return YES;
}

- (BOOL)validateDeviceProperties:(id *)ioValue error:(NSError * __autoreleasing *)outError
{
    if (([(NSDictionary *)*ioValue count] > 0)) {
        NSDictionary *dict = (NSDictionary *)*ioValue;
        
        for (id key in dict.keyEnumerator) {
            if ([key isKindOfClass:[NSString class]] == NO) {
                if (outError != NULL) {
                    NSString *errorString = NSLocalizedString(@"Device properties dictionary keys must be NSString instances.",
                                                              @"validation: TracksEvent, key type deviceProperties error");
                    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
                    *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                           code:TracksErrorCodeValidationDevicePropertiesKeyType
                                                       userInfo:userInfoDict];
                }
                
                return NO;
            }
            
            if ([self validPropertyName:key] == NO) {
                if (outError != NULL) {
                    NSString *errorString = NSLocalizedString(@"Device properties dictionary keys must contain alpha characters and underscores only.",
                                                              @"validation: TracksEvent, key format deviceProperties error");
                    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
                    *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                           code:TracksErrorCodeValidationDevicePropertiesKeyFormat
                                                       userInfo:userInfoDict];
                }
                
                return NO;
            }
        }
        
        return YES;
    }
    
    return YES;
}

- (BOOL)validateUserProperties:(id *)ioValue error:(NSError * __autoreleasing *)outError
{
    if (([(NSDictionary *)*ioValue count] > 0)) {
        NSDictionary *dict = (NSDictionary *)*ioValue;
        
        for (id key in dict.keyEnumerator) {
            if ([key isKindOfClass:[NSString class]] == NO) {
                if (outError != NULL) {
                    NSString *errorString = NSLocalizedString(@"User properties dictionary keys must be NSString instances.",
                                                              @"validation: TracksEvent, key type userProperties error");
                    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
                    *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                           code:TracksErrorCodeValidationUserPropertiesKeyType
                                                       userInfo:userInfoDict];
                }
                
                return NO;
            }
            
            if ([self validPropertyName:key] == NO) {
                if (outError != NULL) {
                    NSString *errorString = NSLocalizedString(@"User properties dictionary keys must contain alpha characters and underscores only.",
                                                              @"validation: TracksEvent, key format userProperties error");
                    NSDictionary *userInfoDict = @{ NSLocalizedDescriptionKey : errorString };
                    *outError = [[NSError alloc] initWithDomain:TracksErrorDomain
                                                           code:TracksErrorCodeValidationUserPropertiesKeyFormat
                                                       userInfo:userInfoDict];
                }
                
                return NO;
            }
        }
        
        return YES;
    }
    
    return YES;
}

#pragma mark - Private helper methods

- (BOOL)validPropertyName:(NSString *)propertyName
{
    NSError *error;
    NSRegularExpression *regex = [NSRegularExpression regularExpressionWithPattern:TracksPropertiesKeyRegExPattern options:0 error:&error];
    NSArray *matches = [regex matchesInString:propertyName options:0 range:NSMakeRange(0, propertyName.length)];

    return matches.count > 0;
}

//@property (nonatomic, copy) NSString *username;
//@property (nonatomic, copy) NSString *userID;
//@property (nonatomic, copy) NSString *userAgent;
//@property (nonatomic, assign) TracksEventUserType userType;
//@property (nonatomic, readonly) NSMutableDictionary *customProperties;
//@property (nonatomic, readonly) NSMutableDictionary *deviceProperties;
//@property (nonatomic, readonly) NSMutableDictionary *userProperties;


@end
