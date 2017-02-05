//
//  TorXPCServiceListener.h
//  TorXPCService
//
//  Created by Chris Ballinger on 2/5/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

#import "TorXPCServiceProtocol.h"

NS_ASSUME_NONNULL_BEGIN
@protocol TorXPCServiceListener <NSObject>
@required

- (void) statusChanged:(TorXPCServiceStatus)newStatus oldStatus:(TorXPCServiceStatus)oldStatus;

/** Called when the service exits for whatever reason */
- (void) serviceExitedWithError:(nullable NSError*)error;

- (void) circuitReadyWithSocksHost:(NSString*)socksHost
                         socksPort:(in_port_t)socksPort
                     hiddenService:(nullable NSString*)hiddenService;

@end
NS_ASSUME_NONNULL_END
