//
//  TorXPCServiceManager.h
//  TorXPCService
//
//  Created by Chris Ballinger on 2/4/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "TorXPCServiceProtocol.h"
#import "TorXPCServiceListener.h"

NS_ASSUME_NONNULL_BEGIN
/** "org.chatsecure.TorXPCService" */
FOUNDATION_EXPORT NSString *const TorXPCServiceName;

@interface TorXPCServiceManager : NSObject <TorXPCServiceProtocol, TorXPCServiceListener>

@end

NS_ASSUME_NONNULL_END
