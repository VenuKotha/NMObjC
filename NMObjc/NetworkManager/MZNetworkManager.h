//
//  MZNetworkManager.h
//  MZNetworkManager
//
//

#import <Foundation/Foundation.h>

#import "MZNetworkRequest.h"
#import "MZNetworkResponse.h"


@protocol NetworkManagerDelegate<NSObject>
@optional
- (void)didCompleteHttpRequestWithResponse:(NSData *) responseData;
//- (void)didCompleteHttpRequest:(HTTPRequest *) request withStatus:(NSInteger) status;
- (void)didFailHttpRequest:(NSError *)error;
@end

@interface MZNetworkManager : NSObject<NSURLConnectionDataDelegate,NSURLConnectionDelegate>

@property (nonatomic,strong) NSString *baseUrlString;
@property (nonatomic,strong) NSString *connectionTimeout;
@property (nonatomic,strong) NSString *headerAccept;
@property (nonatomic,strong) NSString *headerContentType;
@property (nonatomic) NSUInteger trialCount;
@property(weak,nonatomic) id<NetworkManagerDelegate> networkManagerDelegate;
@property (nonatomic,strong) NSMutableData *receivedDataForAsynchronous;

//For Singleton class implementation
+(id)sharedInstance;


-(BOOL)isNetworkReachable;
-(int)isNetworkType;
-(MZNetworkResponse*)processRequest:(MZNetworkRequest*)networkRequest withWait:(BOOL)isWait;

-(MZNetworkResponse*)processLossyRequest:(MZNetworkRequest*)networkRequest withWait:(BOOL)isWait;

-(void)sendAsynchronousRequest:(NSMutableURLRequest*)networkRequest;
- (MZNetworkResponse*)serviceResponse:(NSMutableURLRequest *)urlRequest withWait:(BOOL)isWait;

@end
