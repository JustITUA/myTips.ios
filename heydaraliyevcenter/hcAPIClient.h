#import <AFNetworking/AFHTTPClient.h>
#import "hcUserAccount.h"

@interface hcAPIClient : AFHTTPClient

+ (hcAPIClient *)sharedClient;

- (void)testWithCompletion:(void(^)(BOOL, NSString *))completion;
- (void)uploadScreenshot:(NSData*)imageData;

@end
