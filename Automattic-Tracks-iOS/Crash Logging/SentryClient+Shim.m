#import "SentryClient+Shim.h"

@interface SentryClient(Internal)
- (SentryEvent *_Nullable)prepareEvent:(SentryEvent *)event
                             withScope:(SentryScope *)scope
                alwaysAttachStacktrace:(BOOL)alwaysAttachStacktrace
                          isCrashEvent:(BOOL)isCrashEvent;
@end

@implementation SentryClient(Shim)

/*
 * A wrapper around a private method in `SentryClient`. If it's unavailable (say the library changes),
 * the worst that should happen is that the stack trace is no longer available on events sent manually using this method.
 *
 * We can remove this once the Sentry SDK allows for capturing events and being notified once they're delivered.
 */
-(SentryEvent *) addStackTraceToEvent:(SentryEvent *) event forClient:(SentryClient *) client {

    SEL selector = @selector(prepareEvent:withScope:alwaysAttachStacktrace:isCrashEvent:);

    if(![client respondsToSelector:selector]) {
        return event;
    }

    SentryScope *scope = [[SentrySDK currentHub] getScope];
    SentryEvent *eventWithStackTrace = [self prepareEvent:event withScope:scope alwaysAttachStacktrace:YES isCrashEvent:NO];

    if(eventWithStackTrace == nil) {
        return event;
    }

    if(eventWithStackTrace.threads.firstObject.stacktrace != nil) {
        eventWithStackTrace.stacktrace = eventWithStackTrace.threads.firstObject.stacktrace;
    }

    return eventWithStackTrace;
}
@end
