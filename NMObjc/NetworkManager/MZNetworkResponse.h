//
//  MZNetworkResponse.h
//  MZNetworkManager
//
//

#import <Foundation/Foundation.h>

@interface MZNetworkResponse : NSObject

@property (nonatomic,strong)NSString *errorMessage;
@property (nonatomic)BOOL isNetworkCallSuccess;
@property (nonatomic,strong)NSData *responseData;

@end
