#import "TracksLogging.h"
#import "Logging.h"

int TracksGetLoggingLevel() {
    return ddLogLevel;
}

void TracksSetLoggingLevel(int level) {
    ddLogLevel = level;
}
