@import Foundation;
#import "UIApplication+Extensions.h"


#if TARGET_OS_IPHONE
@implementation UIApplication (SharedIfAvailable)

+ (UIApplication *)sharedIfAvailable {

    if ([NSBundle.mainBundle.bundleURL.pathExtension isEqualToString:@"appex"]) {
        return nil;
    }

    SEL selector = @selector(sharedApplication);

    Class appClass = NSClassFromString(@"UIApplication");
    if ([appClass respondsToSelector:selector] == NO) {
        return nil;
    }

    IMP imp = [appClass methodForSelector:selector];
    UIApplication * (*func)(id, SEL) = (void *)imp;

    UIApplication *app = func(appClass, selector);
    if ([app isKindOfClass:[UIApplication class]]) {
        return app;
    }

    return nil;
}

@end
#endif
