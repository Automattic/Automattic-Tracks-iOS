#import "TracksLogging.h"
#import "TracksLoggingPrivate.h"

DDLogLevel TracksGetLoggingLevel(void) {
    return tracks_ddLogLevel;
}

void TracksSetLoggingLevel(DDLogLevel level) {
    tracks_ddLogLevel = level;
}
