@import Foundation;

NS_ASSUME_NONNULL_BEGIN

@protocol TracksLoggingDelegate <NSObject>

- (void)logPanic:(NSString *)str;
- (void)logError:(NSString *)str;
- (void)logWarning:(NSString *)str;
- (void)logInfo:(NSString *)str;
- (void)logDebug:(NSString *)str;
- (void)logVerbose:(NSString *)str;

@end

// Free functions for logging through the TracksLogging delegate.
void TracksLogPanic(NSString *str, ...) NS_FORMAT_FUNCTION(1, 2);
void TracksLogError(NSString *str, ...) NS_FORMAT_FUNCTION(1, 2);
void TracksLogWarn(NSString *str, ...) NS_FORMAT_FUNCTION(1, 2);
void TracksLogInfo(NSString *str, ...) NS_FORMAT_FUNCTION(1, 2);
void TracksLogDebug(NSString *str, ...) NS_FORMAT_FUNCTION(1, 2);
void TracksLogVerbose(NSString *str, ...) NS_FORMAT_FUNCTION(1, 2);


@protocol TracksLoggingConfiguration <NSObject>
@property (class, nullable) id<TracksLoggingDelegate> delegate;
@end


/**
 There's some funny layering going on here. We want to
 expose the `TracksLogging` class publicly, and that works
 better if we define it in Swift. If we define it in ObjC,
 then it doesn't get re-exported when we do
 `@_exported import AutomatticTracksModelObjC` in Swift,
 because `@_exported` only re-exports Swift symbols. So then
 all clients end up having to `import AutomatticTracksModelObjC`,
 which isn't really a great experience. So we want to define
 it in Swift

 However, because the ObjC code needs to be able to *use* the
 logging delegate, we need to somehow get access to it from
 a layer higher.

 So what we're doing is having the ObjC code load the Swift
 class using NSClassFromString, and then verify that it
 conforms to the expected protocol. This is effectively
 "reaching up" one layer to access it, but it solves our
 symbol exporting problem.
 */
Class<TracksLoggingConfiguration> TracksLoggingClass(void);


NS_ASSUME_NONNULL_END

