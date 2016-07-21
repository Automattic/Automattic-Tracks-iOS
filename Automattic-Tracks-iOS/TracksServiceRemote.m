#import "TracksServiceRemote.h"

@interface TracksServiceRemote()

@property (nonatomic, strong) NSURLSession *session;

@end

@implementation TracksServiceRemote

- (NSURLSession *)session {
    if (_session == nil) {
        // use an ephemeral configuration because we don't need to keep any kind of permanent cache
        NSURLSessionConfiguration *sessionConfiguration = [NSURLSessionConfiguration ephemeralSessionConfiguration];
        // disable event memory cache
        sessionConfiguration.URLCache = nil;
        _session = [NSURLSession sessionWithConfiguration:sessionConfiguration];
    }

    return _session;
}

- (void)sendBatchOfEvents:(NSArray *)events withSharedProperties:(NSDictionary *)properties completionHandler:(void (^)(NSError *error))completion
{
    NSDictionary *dataToSend = @{@"events" : events,
                                 @"commonProps" : properties};
    NSError *error = nil;
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:@"https://public-api.wordpress.com/rest/v1.1/tracks/record"]];
    request.HTTPMethod = @"POST";
    request.HTTPBody = [NSJSONSerialization dataWithJSONObject:dataToSend options:0 error:&error];
    [request addValue:@"application/json" forHTTPHeaderField:@"Content-Type"];
    [request addValue:@"application/json" forHTTPHeaderField:@"Accept"];
    
    if (self.tracksUserAgent) {
        [request setValue:self.tracksUserAgent forHTTPHeaderField:@"User-Agent"];
    }

    NSURLSessionDataTask *task;
    task = [self.session dataTaskWithRequest:request
                            completionHandler:^(NSData *data, NSURLResponse *response, NSError *completionError)
            {
                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(completionError);
                    });
                }
            }];
    
    [task resume];
}

@end
