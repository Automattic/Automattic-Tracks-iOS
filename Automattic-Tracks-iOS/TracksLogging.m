#import "TracksLogging.h"
#import "TracksLoggingPrivate.h"

int TracksGetLoggingLevel() {
    return ddLogLevel;
}

void TracksSetLoggingLevel(int level) {
    ddLogLevel = level;
}
