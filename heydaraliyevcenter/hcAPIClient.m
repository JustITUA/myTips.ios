#import "hcAPIClient.h"
#import <AFOAuth2Client.h>
#import "hcJSONRequestOperation.h"
#import <Mantle/MTLJSONAdapter.h>
#import <AFNetworking/AFImageRequestOperation.h>
#import <SSKeychain.h>
#import "NSString+Base64.h"

static NSString * const SERVER_DEV = @"http://localhost/myTips/myTips.api/index.php/api";
static NSString * const SERVER_PROD = @"https://api.mbank.ru";

static NSString * const kClientSecret = @"";

static NSString * const kTestPath = @"/test";
static NSString * const kUploadScreenshotPath = @"/screenshot";
static NSString* hcAPIBaseURLString;

@implementation hcAPIClient

+ (instancetype)sharedClient {
    static hcAPIClient *_sharedClient = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // init server URL
        hcAPIBaseURLString = SERVER_DEV;
        _sharedClient = [[self alloc] initWithBaseURL:[NSURL URLWithString:hcAPIBaseURLString]];
    });
    
    return _sharedClient;
}

- (instancetype)initWithBaseURL:(NSURL *)url {
    self = [super initWithBaseURL:url];
    if (!self) {
        return nil;
    }
    [self setDefaultHeader:@"HTTP_X_REQUESTED_WITH" value:@"xmlhttprequest"];
    __weak typeof(self) weakSelf = self;
    
    [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
        NSLog(@"status - %d", status);
        
        if (weakSelf.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN ||
            weakSelf.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi ) {
            
            NSLog(@"connection success");
        }
        else {
            NSLog(@"connection fail");
        }
    }];
    
    return self;
}


- (void)setBasicAuthForRequest:(NSMutableURLRequest *)request
{
    NSString * account = [[[SSKeychain accountsForService:kKeychainServiceName] objectAtIndex:0] objectForKey:@"acct"];
    NSString *basicAuthCredentials = [NSString stringWithFormat:@"%@:%@", account, [SSKeychain passwordForService:kKeychainServiceName account:account]];
     NSString *value = [NSString stringWithFormat:@"Basic %@", [NSString Base64EncodedStringFromString:basicAuthCredentials]];
     [request setValue:value forHTTPHeaderField:@"Authorization"];
}


- (void)checkConnection
{
    __weak typeof(self) weakSelf = self;
    [self setReachabilityStatusChangeBlock:^(AFNetworkReachabilityStatus status){
        NSLog(@"%d", status);
        
        if (weakSelf.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWWAN ||
            weakSelf.networkReachabilityStatus == AFNetworkReachabilityStatusReachableViaWiFi ) {
            
            NSLog(@"connection");
        }
        else {
            NSLog(@"fail");
            UIAlertView * alertView = [[UIAlertView alloc] initWithTitle:@"" message:@"Отсутствует подключение" delegate:nil cancelButtonTitle:@"OK" otherButtonTitles:nil, nil];
            [alertView show];
        }
    }];
}



#pragma mark - HTTP methods

- (void)testWithCompletion:(void(^)(BOOL, NSString *))completion
{
    NSMutableURLRequest* request = [self requestWithMethod:@"GET" path:[NSString stringWithFormat:@"%@%@", hcAPIBaseURLString,kTestPath] parameters:nil];
    hcJSONRequestOperation* operation = [hcJSONRequestOperation JSONRequestOperationWithRequest:request success:^(NSURLRequest *request, NSHTTPURLResponse *response, id JSON) {
        completion(YES, nil);
    } failure:^(NSURLRequest *request, NSHTTPURLResponse *response, NSError *error, id JSON) {
        completion(NO, JSON[@"error"][@"message"]);
    }];
    
    operation.JSONReadingOptions = NSJSONReadingAllowFragments;
    [operation start];
}

- (void)uploadScreenshot:(NSData*)imageData
{
    if (imageData != nil)
    {
        NSString *urlString = [NSString stringWithFormat:@"%@%@", hcAPIBaseURLString,kUploadScreenshotPath];
        
        NSString* filenames = [NSString stringWithFormat:@"FileName"];
        NSLog(@"%@", filenames);
        
        NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
        [request setURL:[NSURL URLWithString:urlString]];
        [request setHTTPMethod:@"POST"];
        
        NSString *boundary = @"---------------------------14737809831466499882746641449";
        NSString *contentType = [NSString stringWithFormat:@"multipart/form-data; boundary=%@",boundary];
        [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
        
        NSMutableData *body = [NSMutableData data];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[[NSString stringWithFormat:@"Content-Disposition: form-data; name=\"filenames\"\r\n\r\n"] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[filenames dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[@"Content-Disposition: form-data; name=\"userfile\"; filename=\"file.png\"\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        
        [body appendData:[@"Content-Type: application/octet-stream\r\n\r\n" dataUsingEncoding:NSUTF8StringEncoding]];
        [body appendData:[NSData dataWithData:imageData]];
        [body appendData:[[NSString stringWithFormat:@"\r\n--%@--\r\n",boundary] dataUsingEncoding:NSUTF8StringEncoding]];
        // setting the body of the post to the reqeust
        [request setHTTPBody:body];
        // now lets make the connection to the web
        NSData *returnData = [NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
        NSString *returnString = [[NSString alloc] initWithData:returnData encoding:NSUTF8StringEncoding];
        NSLog(@"%@", returnString);
        NSLog(@"finish");
    }

}


@end
