//
//  MZNetworkRequest.m
//  MZNetworkManager
//
//

#import "MZNetworkRequest.h"

@implementation MZNetworkRequest

@synthesize accept;
@synthesize baseURL;
@synthesize contentType;
@synthesize queryParameters;
@synthesize requestData;
@synthesize requestType;
@synthesize serviceURL;
@synthesize fileRequestData;
@synthesize isFileDataRequest;

-(id)init
{
    //call the init method implemented by the super class
    self = [super init];
    if(self)
    {
        self.accept = @"";
        self.baseURL = @"";
        self.contentType = @"";
        self.queryParameters = [[NSArray alloc]init];
        self.requestData = @"";
        self.requestType = @"";
        self.serviceURL = @"";
        self.fileRequestData = [[NSData alloc] init];
        self.isFileDataRequest = NO;
    }
    return self;
}

@end
