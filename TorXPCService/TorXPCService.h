//
//  TorXPCService.h
//  TorXPCService
//
//  Created by Chris Ballinger on 1/29/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

@import Foundation;
@import TorXPCInterface;


@interface TorXPCService : NSObject <TorXPCServiceProtocol>

@property (nonatomic, strong) id<TorXPCServiceListener> listener;

@end

