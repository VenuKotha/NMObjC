//
//  MZNetworkResponse.m
//  MZNetworkManager
//
//

#import "MZNetworkResponse.h"

@implementation MZNetworkResponse

@synthesize errorMessage;
@synthesize isNetworkCallSuccess;
@synthesize responseData;


-(id)init
{
    if(self = [super init])
    {
        self.errorMessage = @"";
        self.isNetworkCallSuccess = NO;
        self.responseData = nil;
        
    }
    return self;
}

@end
