//
//  MZNetworkDetails.m
//  MZNetworkManager
//
//

#import "MZNetworkDetails.h"

@implementation MZNetworkDetails

@synthesize  downloadSpeed;
@synthesize  networkType;
@synthesize  uploadSpeed;

-(id)init
{
    //call the init method implemented by the super class
    self = [super init];
    if(self)
    {
        self.downloadSpeed = 0;
        self.networkType = @"";
        self.uploadSpeed = 0;
    }
    return self;
}

@end
