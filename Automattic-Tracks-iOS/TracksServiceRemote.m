#import "TracksServiceRemote.h"
#import "TracksConstants.h"

@interface TracksServiceRemote()

@property (nonatomic, strong) NSURLSession *session;
@property (nonatomic, strong) NSIndexSet *acceptableStatusCodes;

@end

@implementation TracksServiceRemote

- (instancetype)init
{
    self = [super init];
    if (self) {
        _acceptableStatusCodes = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(200, 100)];
    }
    return self;
}

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

-(void)sendBatchOfEvents:(NSArray<TracksEvent *> *)events
    withSharedProperties:(NSDictionary *)properties
       completionHandler:(void (^)(NSError * _Nullable))completion
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
                            completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error)
            {
                NSHTTPURLResponse *httpResponse = [response isKindOfClass:[NSHTTPURLResponse class]] ? (NSHTTPURLResponse *)response : nil;

                // Only allow HTTP 200-299 response codes
                if (error == nil && ![self.acceptableStatusCodes containsIndex:(NSUInteger)httpResponse.statusCode]) {
                    error = [NSError errorWithDomain:TracksErrorDomain
                                                code:TracksErrorRemoteResponseError
                                            userInfo:@{NSLocalizedDescriptionKey: @"Invalid HTTP response received from host."}];
                }

                // A successful request will have a response of "Accepted" in JSON foramt
                if (error == nil && data != nil) {
                    NSString *responseData = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
                    BOOL validResponseData = [responseData isEqualToString:@"\"Accepted\""];

                    if (!validResponseData) {
                        error = [NSError errorWithDomain:TracksErrorDomain code:TracksErrorRemoteResponseInvalid userInfo:@{NSLocalizedDescriptionKey: @"Invalid response received from host - expected \"Accepted\"."}];
                    }
                }

                if (completion) {
                    dispatch_async(dispatch_get_main_queue(), ^{
                        completion(error);
                    });
                }
            }];
    
    [task resume];
}

@end
