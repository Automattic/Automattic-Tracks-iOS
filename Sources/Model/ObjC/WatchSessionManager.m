#import "WatchSessionManager.h"

#if TARGET_OS_IPHONE
#import <WatchConnectivity/WatchConnectivity.h>

@interface WatchSessionManager()<WCSessionDelegate>

@property(nonatomic, strong) WCSession *session;
#else
@interface WatchSessionManager()
#endif

@property(assign) BOOL hasBeenPaired;

@end

@implementation WatchSessionManager

+ (instancetype)shared
{
    static WatchSessionManager *sharedInstance = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[WatchSessionManager alloc] init];
    });
    return sharedInstance;
}

- (instancetype)init {
    if (self = [super init]) {

        // Return early if we've done this check before
        if([self hasBeenPreviouslyPaired]){
            return self;
        }

#if TARGET_OS_IPHONE
        if([WCSession isSupported]){
            self.session = [WCSession defaultSession];
            
            if (self.session.activationState == WCSessionActivationStateActivated) {
                [self setHasBeenPairedIfPossibleWithSession:self.session];
            } else {
                self.session.delegate = self;
                [self.session activateSession];
            }
          

            self.hasBeenPaired = false;
        }
#endif
    }

    return self;
}

- (void)setHasBeenPairedIfPossibleWithSession:(nonull WCSession *)session {
    if(session.paired){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"watch-has-been-previously-paired"];
    }
}

- (BOOL)hasBeenPreviouslyPaired{
    BOOL result = [[NSUserDefaults standardUserDefaults] boolForKey:@"watch-has-been-previously-paired"];
    return result;
}

#pragma mark – WCSessionDelegate

#if TARGET_OS_IPHONE
- (void)session:(nonnull WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {

    [self setHasBeenPairedIfPossibleWithSession:session];
}

- (void)sessionDidBecomeInactive:(nonnull WCSession *)session {

}

- (void)sessionDidDeactivate:(nonnull WCSession *)session {

}
#endif
@end
