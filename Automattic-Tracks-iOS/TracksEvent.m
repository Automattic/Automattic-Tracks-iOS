#import "TracksEvent.h"

@implementation TracksEvent

NSString *const TracksEventNameRegExPattern = @"^[a-z_][a-z0-9_]*$";

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
    
    BOOL nameValid = [self validateValue:&eventName forKey:@"eventName" error:error];
    
    return nameValid;
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
    } else if ([(NSString *)*ioValue containsString:@"-"]) {
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

//@property (nonatomic, copy) NSString *username;
//@property (nonatomic, copy) NSString *userID;
//@property (nonatomic, copy) NSString *userAgent;
//@property (nonatomic, assign) TracksEventUserType userType;
//@property (nonatomic, readonly) NSMutableDictionary *customProperties;
//@property (nonatomic, readonly) NSMutableDictionary *deviceProperties;
//@property (nonatomic, readonly) NSMutableDictionary *userProperties;


@end
