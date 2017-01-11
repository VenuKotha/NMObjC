//
//  MZNetworkManager.m
//  MZNetworkManager
//
//


#import "MZNetworkManager.h"
#import "Reachability.h"
#import "NMSwift-Swift.h"

@interface MZNetworkManager()
@property(nonatomic, strong) NetworkManager *networkManagerSwiftObj;
-(NSMutableURLRequest *)createURLRequest:(MZNetworkRequest*)networkRequest;
-(NSDictionary *)attachTheCookie;
-(void)getValuesFromConfigurationPlist;
@end

static MZNetworkManager *sharedMyManager = nil;

@implementation MZNetworkManager
@synthesize  baseUrlString,connectionTimeout,headerAccept,headerContentType,trialCount,receivedDataForAsynchronous,networkManagerDelegate;

//For Singleton class implementation
+ (id)sharedInstance {
    
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedMyManager = [[self alloc] init];
    });
    // self.plistDictionary = [self getValuesFromConfigurationPlist];
    return sharedMyManager;
}

-(id)init
{
    //call the init method implemented by the super class
    self = [super init];
    if(self)
    {
        self.baseUrlString = @"";
        self.connectionTimeout = @"";
        self.headerAccept = @"";
        self.headerContentType = @"";
        //self.trialCount = ;
        [self getValuesFromConfigurationPlist];
    }
    return self;
}

#pragma mark baseMethod implementation

-(MZNetworkResponse*)processRequest:(MZNetworkRequest*)networkRequest withWait:(BOOL)isWait
{
    NSMutableURLRequest *urlRequest = [self createURLRequest:networkRequest];
    _networkManagerSwiftObj = [[NetworkManager alloc]init];
    MZNetworkResponse *networkResponse = [_networkManagerSwiftObj serviceResponse:urlRequest isWait:YES];
    return networkResponse;
    //return [self serviceResponse:urlRequest withWait:isWait];
}

-(MZNetworkResponse*)processLossyRequest:(MZNetworkRequest*)networkRequest withWait:(BOOL)isWait
{
    NSMutableURLRequest *urlRequest = [self createLossyURLRequest:networkRequest];
    return [self serviceResponse:urlRequest withWait:isWait];
}
- (MZNetworkResponse*)serviceResponse:(NSMutableURLRequest *)urlRequest withWait:(BOOL)isWait {
    MZNetworkResponse *response = [[MZNetworkResponse alloc]init];
    if([self isNetworkReachable])
    {
        NSHTTPURLResponse   * httpResponse = nil;
        NSError             * error=nil;
        NSData *responseDataObj = nil;
        //handling try, catch blocks for exception handling
        @try {
            if(isWait)
            {
                responseDataObj = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&httpResponse error:&error];
                
                //For Connection timeout and Trial count code handling
                if([[error domain] isEqualToString:@"NSURLErrorDomain"]&&[error code]==kCFURLErrorTimedOut)
                {
                    httpResponse = nil;
                    error = nil;
                    responseDataObj = nil;
                    if(self.trialCount >1)
                    {
                        for(int i=0;i<self.trialCount;i++)
                        {
                            httpResponse = nil;
                            error = nil;
                            responseDataObj = nil;
                            
                            responseDataObj = [NSURLConnection sendSynchronousRequest:urlRequest returningResponse:&httpResponse error:&error];
                            if([[error domain] isEqualToString:@"NSURLErrorDomain"]&&[error code]==kCFURLErrorTimedOut)
                            {
                                continue;
                            }
                            else
                            {
                                break;
                                
                            }
                        }
                    }
                }
                
                if ((httpResponse.statusCode >= 200 &&
                     httpResponse.statusCode < 300) || ((httpResponse.statusCode >= 400 && httpResponse.statusCode <= 500) && httpResponse.statusCode != 403)) {
                    response.isNetworkCallSuccess = YES;
                    response.errorMessage = nil;
                    response.responseData = responseDataObj;
                }
                else if(httpResponse.statusCode == 403){
                    response.isNetworkCallSuccess = NO;
                    response.errorMessage = @"Session Expired! Please Logout and Login Again";
                    response.responseData = nil;
                }
                else if(httpResponse.statusCode == 502){
                    response.isNetworkCallSuccess = NO;
                    response.errorMessage = @"Bad Gateway";
                    response.responseData = nil;
                }
                else if(httpResponse.statusCode == 503){
                    response.isNetworkCallSuccess = NO;
                    response.errorMessage = @"Bad Gateway";
                    response.responseData = nil;
                }
                else if(httpResponse.statusCode == 504){
                    response.isNetworkCallSuccess = NO;
                    response.errorMessage = @"Gateway Timeout";
                    response.responseData = nil;
                }
                else if(httpResponse.statusCode == 505){
                    response.isNetworkCallSuccess = NO;
                    response.errorMessage = @"Http version not supported";
                    response.responseData = nil;
                }
                else if ([error code] == kCFURLErrorUserCancelledAuthentication) {
                    response.isNetworkCallSuccess = NO;
                    response.errorMessage = @"Session Expired! Please Logout and Login Again";//For Trimble Release we modified @"The connection failed because the user cancelled required authentication.";
                    response.responseData = nil;
                }
                else{
                    response.isNetworkCallSuccess = NO;
                    response.errorMessage = @"No Proper Response From Server";
                    response.responseData = nil;
                }

            }
            else
            {
                receivedDataForAsynchronous = [NSMutableData dataWithCapacity: 0];
                [self sendAsynchronousRequest:urlRequest];
                return nil;
            }
            
        }
        
        @catch (NSException *exception) {
            //error.localizedDescription = exception.description
            response.isNetworkCallSuccess = NO;
            response.errorMessage = exception.description;
            response.responseData = nil;
            return response;
        }
    }
    else
    {
        response.isNetworkCallSuccess = NO;
        response.errorMessage = @"Device Not Connected to Internet";
        response.responseData = nil;
    }
    
    return response;
}


-(void)sendAsynchronousRequest:(NSMutableURLRequest*)asyncRequest
{
    NSURLConnection *theConnection=[[NSURLConnection alloc] initWithRequest:asyncRequest delegate:self];
    [theConnection scheduleInRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [theConnection start];
}

#pragma mark To check whether device is connected to network or not
-(BOOL)isNetworkReachable
{
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    BOOL isNetworkReachable;
    switch (netStatus)
    {
        case NotReachable:        {
            
            isNetworkReachable=NO;
            break;
        }
            
        case ReachableViaWWAN:        {
            isNetworkReachable=YES;
            break;
        }
        case ReachableViaWiFi:        {
            isNetworkReachable=YES;
            break;
        }
        default:{
            
            NSError* error = nil;
            NSString* locationString = [NSString stringWithContentsOfURL:[NSURL URLWithString:@"http://www.google.com"] encoding:NSASCIIStringEncoding error:&error];
            isNetworkReachable = ( locationString != NULL ) ? YES : NO;
        }
    }
    
    return isNetworkReachable;
}


-(int)isNetworkType
{
    Reachability* reachability = [Reachability reachabilityForInternetConnection];
    NetworkStatus netStatus = [reachability currentReachabilityStatus];
    return netStatus;
}



#pragma mark to get values from pList file
-(void)getValuesFromConfigurationPlist
{
    /*NSString *path = nil;
    NSArray* allAppBundles = [NSBundle allBundles];
    for( NSBundle* appBundle in allAppBundles )
    {
        if([appBundle pathForResource:@"MZNetworkConnection" ofType:@"plist"] != nil)
        {
            path = [appBundle pathForResource:@"MZNetworkConnection" ofType:@"plist" ];
        }
    }*/
    //NSString *path = [[NSBundle mainBundle] pathForResource: @"NetworkConfigurations" ofType: @"plist"];
    //code modified as below to get the xxxxx_NetworkConfigurations file based on the project on 25th December 2015 by Venu
    BOOL appCategory = [[[NSUserDefaults standardUserDefaults] objectForKey:@"appCategory"] boolValue];
    NSString *fileName = nil;
    //apppCategory is YES for customer projects and NO for base(ChannelConnect) project
    if (appCategory) {
        fileName= [[[NSBundle mainBundle]infoDictionary]objectForKey:@"CFBundleName"];
        fileName = [fileName stringByAppendingFormat:@"_%@",@"NetworkConfigurations"];
    }
    else
    {
        fileName = @"NetworkConfigurations";
    }
    NSString *path = [[NSBundle mainBundle] pathForResource: fileName ofType: @"plist"];
    NSDictionary *dictionary = [[NSDictionary alloc] initWithContentsOfFile:path];
    self.baseUrlString = [dictionary objectForKey:@"baseURL"] ;
    
    
    self.connectionTimeout = [dictionary objectForKey:@"connectionTimeout"];
    self.trialCount = [[dictionary objectForKey:@"trailCount"] intValue];
    self.headerContentType = [dictionary objectForKey:@"headerContentType"];
    
}



#pragma mark Private methods

-(NSMutableURLRequest *)createURLRequest:(MZNetworkRequest*)networkRequest{
    
    // NSMutableString *baseURLString = nil;
    NSURL *url = nil;
    
    //condition added to use properties list baseurl as default when baseURL string is nil in networkRequest
    if([networkRequest.baseURL length]>0) {
        [self getValuesFromConfigurationPlist];
        self.baseUrlString = networkRequest.baseURL;
    }
    
    //frame the final url and set the time out
    //[self.baseUrlString appendString:@"/"];
    //[self.baseUrlString appendString:networkRequest.serviceURL];
    NSString *saveURL = [NSString stringWithFormat:@"%@/%@",self.baseUrlString,networkRequest.serviceURL];
    NSString *encodedURL = [saveURL stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
    NSLog(@"URL string is %@",encodedURL);
    url = [[NSURL alloc] initWithString:encodedURL];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url
                                                                   cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:[self.connectionTimeout doubleValue]];
    
    //add query parameters to the url to make final URL
    //   NSArray *keyValues = [networkRequest.queryParameters allKeys];
    //    for (NSString *strKey in keyValues) {
    //        [urlRequest addValue:[networkRequest.queryParameters objectForKey:strKey] forHTTPHeaderField:strKey];
    //    }
    //
    
    
    //add cookie to URL
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    [urlRequest setAllHTTPHeaderFields:[self attachTheCookie]];
    
    [urlRequest addValue:networkRequest.accept forHTTPHeaderField:@"Accept"];
    [urlRequest addValue:networkRequest.contentType forHTTPHeaderField:@"Content-Type"];
    
    if([networkRequest.requestType isEqualToString:@"GET"]) {
        [urlRequest setHTTPMethod:@"GET"];
    }
    else if([networkRequest.requestType isEqualToString:@"DELETE"]) {
        [urlRequest setHTTPMethod:@"DELETE"];
    }
    else if([networkRequest.requestType isEqualToString:@"POST"]) {
        [urlRequest setHTTPMethod:@"POST"];
        if (networkRequest.isFileDataRequest == YES) {
            [urlRequest setHTTPBody:networkRequest.fileRequestData];
        }
        else {
            [urlRequest setHTTPBody:[networkRequest.requestData dataUsingEncoding:NSUTF8StringEncoding]];
        }
    }
    return urlRequest;
}

-(NSMutableURLRequest *)createLossyURLRequest:(MZNetworkRequest*)networkRequest{
    
    // NSMutableString *baseURLString = nil;
    NSURL *url = nil;
    
    //condition added to use properties list baseurl as default when baseURL string is nil in networkRequest
    if([networkRequest.baseURL length]>0) {
        [self getValuesFromConfigurationPlist];
        self.baseUrlString = networkRequest.baseURL;
    }
    
    //frame the final url and set the time out
    //[self.baseUrlString appendString:@"/"];
    //[self.baseUrlString appendString:networkRequest.serviceURL];
    NSString *saveURL = [NSString stringWithFormat:@"%@/%@",self.baseUrlString,networkRequest.serviceURL];
    
    saveURL = [saveURL stringByReplacingOccurrencesOfString:@" " withString:@"%20"];
    saveURL = [saveURL stringByReplacingOccurrencesOfString:@"," withString:@"%2C"];
    NSData *ASCIIData = [saveURL dataUsingEncoding:NSASCIIStringEncoding allowLossyConversion:YES];
    NSString *encodedURL = [[NSString alloc] initWithData:ASCIIData encoding:NSASCIIStringEncoding];
    NSLog(@"URL string is %@",encodedURL);
    url = [[NSURL alloc] initWithString:encodedURL];
    NSMutableURLRequest *urlRequest = [[NSMutableURLRequest alloc] initWithURL:url
                                                                   cachePolicy:NSURLRequestReloadIgnoringCacheData timeoutInterval:[self.connectionTimeout doubleValue]];
    
    //add query parameters to the url to make final URL
    //   NSArray *keyValues = [networkRequest.queryParameters allKeys];
    //    for (NSString *strKey in keyValues) {
    //        [urlRequest addValue:[networkRequest.queryParameters objectForKey:strKey] forHTTPHeaderField:strKey];
    //    }
    //
    
    
    //add cookie to URL
    NSHTTPCookieStorage *cookieStorage = [NSHTTPCookieStorage sharedHTTPCookieStorage];
    [cookieStorage setCookieAcceptPolicy:NSHTTPCookieAcceptPolicyAlways];
    [urlRequest setAllHTTPHeaderFields:[self attachTheCookie]];
    
    [urlRequest addValue:networkRequest.accept forHTTPHeaderField:@"Accept"];
    [urlRequest addValue:networkRequest.contentType forHTTPHeaderField:@"Content-Type"];
    
    if([networkRequest.requestType isEqualToString:@"GET"])
    {
        [urlRequest setHTTPMethod:@"GET"];
        
    }
    if([networkRequest.requestType isEqualToString:@"POST"])
    {
        [urlRequest setHTTPMethod:@"POST"];
        if (networkRequest.isFileDataRequest == YES) {
            
            [urlRequest setHTTPBody:networkRequest.fileRequestData];
            
        }
        else{
            [urlRequest setHTTPBody:[networkRequest.requestData dataUsingEncoding:NSUTF8StringEncoding]];
            
        }
        
        
    }
    
    
    return urlRequest;
}

-(NSDictionary *)attachTheCookie
{
    
    NSDictionary * savedCookieData = [[NSUserDefaults standardUserDefaults]objectForKey:@"ccCookie"];
    NSDictionary *cookieProperties;
    if ([savedCookieData respondsToSelector:@selector(count)]) {
        
        //NSLog(@"here1");
        cookieProperties= [NSDictionary dictionaryWithObjectsAndKeys:
                           [savedCookieData objectForKey:@"domain"], NSHTTPCookieDomain,
                           [savedCookieData objectForKey:@"path"], NSHTTPCookiePath,
                           [savedCookieData objectForKey:@"name"], NSHTTPCookieName,
                           [savedCookieData objectForKey:@"value"], NSHTTPCookieValue,
                           nil];
    }else{
        
        //NSLog(@"here2");
        cookieProperties= [NSDictionary dictionaryWithObjectsAndKeys:
                           @"", NSHTTPCookieDomain,
                           @"", NSHTTPCookiePath,
                           @"", NSHTTPCookieName,
                           @"", NSHTTPCookieValue,
                           nil];
    }
    
    ///NSLog(@"here3");
    
    NSHTTPCookie *cookie = [NSHTTPCookie cookieWithProperties:cookieProperties];
    NSArray* cookieArray = [NSArray arrayWithObjects: cookie, nil];
    NSDictionary * headers = [NSHTTPCookie requestHeaderFieldsWithCookies:cookieArray];
    
    //NSLog(@"cookieArray=%@",cookieArray);
    return headers;
}


#pragma mark NetworkManager connection delegates in case of no wait
- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{
    NSLog(@"IN %@ method",NSStringFromSelector(_cmd));
    [receivedDataForAsynchronous setLength:0];
    
}
- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    NSLog(@"IN %@ method",NSStringFromSelector(_cmd));
    
    [receivedDataForAsynchronous appendData:data];
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)err
{
    NSLog(@"IN %@ method",NSStringFromSelector(_cmd));
    receivedDataForAsynchronous = nil;
    
    //error = [err copy];
    
    if ([networkManagerDelegate respondsToSelector:@selector(didFailHttpRequest:)])
        [networkManagerDelegate didFailHttpRequest:[err copy]];
    
    [connection cancel] ;
    [connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop]forMode:NSDefaultRunLoopMode];
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    NSLog(@"IN %@ method",NSStringFromSelector(_cmd));
    
    if ([networkManagerDelegate respondsToSelector:@selector(didCompleteHttpRequestWithResponse:)])
        [networkManagerDelegate didCompleteHttpRequestWithResponse:receivedDataForAsynchronous];
    
    MZNetworkResponse *response = [[MZNetworkResponse alloc]init];
    response.responseData = receivedDataForAsynchronous;
    
    [connection cancel] ;
    //[connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop]
    //                        forMode:NSDefaultRunLoopMode];
    
}
@end



