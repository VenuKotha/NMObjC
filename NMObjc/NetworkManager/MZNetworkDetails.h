//
//  MZNetworkDetails.h
//  MZNetworkManager
//
//

#import <Foundation/Foundation.h>

@interface MZNetworkDetails : NSObject

@property int downloadSpeed;
@property(strong,nonatomic) NSString* networkType;
@property int uploadSpeed;

@end
