//
//  TorXPCServiceManager.m
//  TorXPCService
//
//  Created by Chris Ballinger on 2/4/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

#import "TorXPCServiceManager.h"

NSString *const TorXPCServiceName = @"org.chatsecure.TorXPCService";

@interface TorXPCServiceManager()
@property (nonatomic, strong, readonly, nullable) NSXPCConnection *connection;
@property (nonatomic, strong, readonly, nullable) id<TorXPCServiceProtocol> service;
@end

@implementation TorXPCServiceManager

- (void) dealloc {
    [self teardown];
}

- (instancetype) init {
    if (self = [super init]) {
    }
    return self;
}

#pragma mark TorXPCServiceProtocol

- (void)setupWithInternalPort:(uint16_t)internalPort externalPort:(uint16_t)externalPort serviceDirectoryName:(NSString * _Nonnull)serviceDirectoryName {
    if (_connection) {
        return;
    }
    _connection = [[NSXPCConnection alloc] initWithServiceName:TorXPCServiceName];
    self.connection.exportedObject = self;
    self.connection.exportedInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TorXPCServiceListener)];
    self.connection.remoteObjectInterface = [NSXPCInterface interfaceWithProtocol:@protocol(TorXPCServiceProtocol)];
    [self.connection resume];
    _service = [self.connection remoteObjectProxyWithErrorHandler:^(NSError * _Nonnull error) {
        NSLog(@"Tor service error: %@", error);
    }];
    [self.service setupWithInternalPort:internalPort
                           externalPort:externalPort
                   serviceDirectoryName:serviceDirectoryName];
}

- (void) teardown {
    if (self.service) {
        [self.service teardown];
    }
    if (self.connection) {
        [self.connection invalidate];
    }
    _connection = nil;
    _service = nil;
}

- (void) getStatus:(void(^ _Nonnull )(TorXPCServiceStatus status, NSError * _Nullable error))statusBlock {
    [self.service getStatus:statusBlock];
}

#pragma mark TorXPCServiceListener

/** Called when the service exits for whatever reason */
- (void) serviceExitedWithError:(nullable NSError*)error {
    NSLog(@"Service exited: %@", error);
    _service = nil; // preemptively nil out service so teardown doesnt recreate it
    [self teardown];
}

- (void) statusChanged:(TorXPCServiceStatus)newStatus oldStatus:(TorXPCServiceStatus)oldStatus {
    NSLog(@"status change: %d -> %d", oldStatus, newStatus);
}

- (void) circuitReadyWithSocksHost:(NSString*)socksHost
                         socksPort:(in_port_t)socksPort
                     hiddenService:(NSString*)hiddenService {
    NSLog(@"circuit ready: %@ %d %@", socksHost, socksPort, hiddenService);
}

@end
