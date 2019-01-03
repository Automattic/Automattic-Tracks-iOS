#import "WatchSessionManager.h"
#import <WatchConnectivity/WatchConnectivity.h>

@interface WatchSessionManager()<WCSessionDelegate>

@property(nonatomic, strong) WCSession *session;
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

        if([WCSession isSupported]){
            self.session = [WCSession defaultSession];
            self.session.delegate = self;
            [self.session activateSession];

            self.hasBeenPaired = false;
        }
    }

    return self;
}

- (BOOL)hasBeenPreviouslyPaired{
    BOOL result = [[NSUserDefaults standardUserDefaults] boolForKey:@"watch-has-been-previously-paired"];
    return result;
}

#pragma mark – WCSessionDelegate
- (void)session:(nonnull WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {

    if(session.paired){
        [[NSUserDefaults standardUserDefaults] setBool:YES forKey:@"watch-has-been-previously-paired"];
    }
}

- (void)sessionDidBecomeInactive:(nonnull WCSession *)session {

}

- (void)sessionDidDeactivate:(nonnull WCSession *)session {

}

@end
