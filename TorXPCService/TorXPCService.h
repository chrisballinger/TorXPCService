//
//  TorXPCService.h
//  TorXPCService
//
//  Created by Chris Ballinger on 1/29/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

@import Foundation;
@import TorXPCInterface;

// This object implements the protocol which we have defined. It provides the actual behavior for the service. It is 'exported' by the service to make it available to the process hosting the service over an NSXPCConnection.
@interface TorXPCService : NSObject <TorXPCServiceProtocol>
@end
