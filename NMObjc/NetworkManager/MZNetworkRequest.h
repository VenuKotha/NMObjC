//
//  MZNetworkRequest.h
//  MZNetworkManager
//
//

#import <Foundation/Foundation.h>

@interface MZNetworkRequest : NSObject

@property (nonatomic,strong) NSString *accept;
@property (nonatomic,strong) NSString *baseURL;
@property (nonatomic,strong) NSString *contentType;
@property (nonatomic,strong) NSArray  *queryParameters;
@property (nonatomic,strong) NSString *requestData;
@property (nonatomic,strong) NSString *requestType;
@property (nonatomic,strong) NSString *serviceURL;
@property (nonatomic,strong) NSData* fileRequestData;
@property (nonatomic) BOOL isFileDataRequest;

@end
