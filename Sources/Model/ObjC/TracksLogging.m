#import "TracksLogging.h"
@import Foundation;
@import ObjectiveC;


Class<TracksLoggingConfiguration> TracksLoggingClass() {
    static Class<TracksLoggingConfiguration> result = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
#if SWIFT_PACKAGE
        Class loggingClass = NSClassFromString(@"AutomatticTracksModel.TracksLogging");
#else
        Class loggingClass = NSClassFromString(@"TracksLogging");
#endif
        if ([loggingClass conformsToProtocol: @protocol(TracksLoggingConfiguration)]) {
            result = loggingClass;
        }
    });
    return result;
}


void TracksLogError(NSString *format, ...) {
    va_list args;
    va_start(args, format);

    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    [[TracksLoggingClass() delegate] logError:str];

    va_end(args);
}

void TracksLogWarn(NSString *format, ...) {
    va_list args;
    va_start(args, format);

    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    [[TracksLoggingClass() delegate] logWarning:str];

    va_end(args);
}

void TracksLogInfo(NSString *format, ...) {
    va_list args;
    va_start(args, format);

    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    [[TracksLoggingClass() delegate] logInfo:str];

    va_end(args);
}

void TracksLogDebug(NSString *format, ...) {
    va_list args;
    va_start(args, format);

    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    [[TracksLoggingClass() delegate] logDebug:str];

    va_end(args);
}

void TracksLogVerbose(NSString *format, ...) {
    va_list args;
    va_start(args, format);

    NSString *str = [[NSString alloc] initWithFormat:format arguments:args];
    [[TracksLoggingClass() delegate] logVerbose:str];

    va_end(args);
}
