#import "TracksLogging.h"
#import "TracksLoggingPrivate.h"

DDLogLevel TracksGetLoggingLevel(void) {
    return ddLogLevel;
}

void TracksSetLoggingLevel(DDLogLevel level) {
    ddLogLevel = level;
}
