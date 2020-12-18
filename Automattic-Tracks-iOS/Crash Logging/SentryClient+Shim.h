#import <Foundation/Foundation.h>
#import <Sentry/Sentry.h>

NS_ASSUME_NONNULL_BEGIN

@interface SentryClient(Shim)
-(SentryEvent *) tryAddingStackTraceToEvent:(SentryEvent *) event forClient:(SentryClient *) client;
@end

NS_ASSUME_NONNULL_END
