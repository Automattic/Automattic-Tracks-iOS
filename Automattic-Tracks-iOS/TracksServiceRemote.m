#import "TracksServiceRemote.h"

@implementation TracksServiceRemote

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
    
    NSURLSession *sharedSession = [NSURLSession sharedSession];
    
    NSURLSessionDataTask *task;
    task = [sharedSession dataTaskWithRequest:request
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
