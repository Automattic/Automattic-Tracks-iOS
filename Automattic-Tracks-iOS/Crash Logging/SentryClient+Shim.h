#import <Foundation/Foundation.h>
@import Sentry;

NS_ASSUME_NONNULL_BEGIN

@interface SentryClient(Shim)
-(SentryEvent *) addStackTraceToEvent:(SentryEvent *) event forClient:(SentryClient *) client;
@end

NS_ASSUME_NONNULL_END
