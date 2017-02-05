//
//  TorXPCServiceProtocol.h
//  TorXPCService
//
//  Created by Chris Ballinger on 1/29/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSUInteger, TorXPCServiceStatus) {
    TorXPCServiceStatusStopped,
    TorXPCServiceStatusStarting,
    TorXPCServiceStatusReady,
    TorXPCServiceStatusShutdown,
    TorXPCServiceStatusError
};

@protocol TorXPCServiceProtocol <NSObject>
@required

- (void) getStatus:(void(^ _Nonnull )(TorXPCServiceStatus status, NSError * _Nullable lastError))statusBlock;

/** For setting up hidden services. */
- (void)setupWithInternalPort:(in_port_t)internalPort
                 externalPort:(in_port_t)externalPort
         serviceDirectoryName:(NSString * _Nonnull)serviceDirectoryName;

/** This will terminate the process */
- (void)teardown;
   
@end
