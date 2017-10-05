#import "TracksLogging.h"
#import "TracksLoggingPrivate.h"

int TracksGetLoggingLevel(void) {
    return ddLogLevel;
}

void TracksSetLoggingLevel(int level) {
    ddLogLevel = level;
}
