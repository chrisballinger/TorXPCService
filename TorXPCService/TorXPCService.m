//
//  TorXPCService.m
//  TorXPCService
//
//  Created by Chris Ballinger on 1/29/17.
//  Copyright © 2017 ChatSecure. All rights reserved.
//

#import "TorXPCService.h"
#import "TorOnionService.h"
@import Tor;

#ifndef DEBUG
const char *kTorArgsValueLogLevel = "warn stderr";
#else
const char *kTorArgsValueLogLevel = "notice stderr";
#endif



@interface TorXPCService()
@property (nonatomic, strong, nullable) TORThread *thread;
@property (nonatomic, strong, nullable) TORController *controller;
/** No longer respond once teardown is called */
@property (nonatomic) TorXPCServiceStatus status;
@property (nonatomic, strong) NSError *lastError;
@end

@implementation TorXPCService

- (void) dealloc {
    [self teardown];
}

- (instancetype) init {
    if (self = [super init]) {
        _status = TorXPCServiceStatusStopped;
        [NSProcessInfo processInfo].automaticTerminationSupportEnabled = YES;
        [[NSProcessInfo processInfo] disableAutomaticTermination:NSStringFromClass(self.class)];
    }
    return self;
}

- (void) threadShutdown:(NSNotification*)notif {
    NSLog(@"thread shutdown: %@", notif);
    self.lastError = [NSError errorWithDomain:TorXPCServiceName code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Tor thread exited."}];
    [self teardown];
}

- (void) setStatus:(TorXPCServiceStatus)newStatus {
    [self willChangeValueForKey:NSStringFromSelector(@selector(status))];
    TorXPCServiceStatus oldStatus = _status;
    _status = newStatus;
    [self.listener statusChanged:newStatus oldStatus:oldStatus];
    [self didChangeValueForKey:NSStringFromSelector(@selector(status))];
}

- (void) getStatus:(void(^ _Nonnull )(TorXPCServiceStatus status, NSError * _Nullable error))statusBlock {
    statusBlock(self.status, self.lastError);
}

- (void)teardown {
    if (self.status == TorXPCServiceStatusShutdown) {
        return;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    self.status = TorXPCServiceStatusShutdown;
    self.thread = nil;
    
    /* TODO: add clean shutdown
    [self.torManager cpa_sendSignal:@"SHUTDOWN" completionBlock:^(NSString *responseString, NSError *error) {
        NSLog(@"Tor Shutdown: %@ %@", responseString, error);
    } completionQueue:dispatch_get_main_queue()];
    */

    
    [self.listener serviceExitedWithError:self.lastError];
    
    [[NSProcessInfo processInfo] enableAutomaticTermination:NSStringFromClass(self.class)];
    [[NSProcessInfo processInfo] enableSuddenTermination];
    // hack to really exit
    //exit(0);
}

- (void)setupWithInternalPort:(in_port_t)internalPort externalPort:(in_port_t)externalPort serviceDirectoryName:(NSString *)serviceDirectoryName {
    if (self.status != TorXPCServiceStatusStopped) {
        //self.lastError = [NSError errorWithDomain:TorXPCServiceName code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Cannot call setup more than once per process."}];
        return;
    }
    NSLog(@"Starting Tor...");
    self.status = TorXPCServiceStatusStarting;
    
    NSError *error = nil;
    NSURL *appSupport = [[[NSFileManager defaultManager] URLsForDirectory:NSApplicationSupportDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *dataDirectory = [[appSupport URLByAppendingPathComponent:TorXPCServiceName] path];
    BOOL success = [[NSFileManager defaultManager] createDirectoryAtPath:dataDirectory withIntermediateDirectories:YES attributes:nil error:&error];
    //NSString *homeDirectory = NSHomeDirectory();
    NSURL *controlSocket = [[NSURL fileURLWithPath:dataDirectory] URLByAppendingPathComponent:@"control_port"];
    TORConfiguration *configuration = [TORConfiguration new];
    configuration.cookieAuthentication = @YES;
    configuration.dataDirectory = [NSURL fileURLWithPath:NSTemporaryDirectory()];
    //configuration.controlSocket = controlSocket;
    
    
    // Load onion services into torrc
    NSURL *docs = [[[NSFileManager defaultManager] URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask] lastObject];
    NSString *hsDir = [[docs URLByAppendingPathComponent:serviceDirectoryName] path];
    TorOnionServicePort *portMapping = [[TorOnionServicePort alloc] initWithAddress:@"127.0.0.1" externalPort:externalPort internalPort:internalPort];
    TorOnionServicePort *xmppC2S = [[TorOnionServicePort alloc] initWithAddress:@"127.0.0.1" externalPort:5222 internalPort:5222];
    TorOnionService *onionService = [[TorOnionService alloc] initWithServiceDirectory:hsDir portMappings:@[portMapping, xmppC2S]];
    
    //NSMutableString *torrcString = [[NSMutableString alloc] initWithContentsOfFile:torrcPath encoding:NSUTF8StringEncoding error:&error];
    NSMutableString *torrcString = [NSMutableString string];
    [torrcString appendString:@"\n\n"];
    [torrcString appendFormat:@"HiddenServiceDir %@\n", hsDir];
    [onionService.portMappings enumerateObjectsUsingBlock:^(TorOnionServicePort * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        [torrcString appendFormat:@"HiddenServicePort %d %@:%d\n", obj.externalPort, obj.address, obj.internalPort];
    }];
    [torrcString appendString:@"\n\n"];
    
    //in_port_t controlPort = 9051;
    //[torrcString appendFormat:@"ControlPort %d\n\n", controlPort];
    
    NSString *newTorrcPath = [dataDirectory stringByAppendingPathComponent:@"torrc"];
    success = [torrcString writeToFile:newTorrcPath atomically:YES encoding:NSUTF8StringEncoding error:&error];
    
    //NSString *torrcArg = [NSString stringWithFormat:@"-f \"%@\"", newTorrcPath];
    //NSString *logArg = [NSString stringWithFormat:@"Log %s", kTorArgsValueLogLevel];
    //configuration.arguments = @[torrcArg, logArg];

    
    self.thread = [[TORThread alloc] initWithConfiguration:configuration];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(threadShutdown:) name:NSThreadWillExitNotification object:self.thread];
    [self.thread start];
    
    
    self.controller = [[TORController alloc] initWithSocketURL:controlSocket];
    
    NSURL *cookieURL = [[NSURL fileURLWithPath:dataDirectory] URLByAppendingPathComponent:@"control_auth_cookie"];
    NSData *cookie = [NSData dataWithContentsOfURL:cookieURL];
    
    void (^circuitEstablished)() = ^{
        [self.controller getSessionConfiguration:^(NSURLSessionConfiguration *configuration) {
            NSError *error = nil;
            if (!configuration) {
                error = [NSError errorWithDomain:TorXPCServiceName code:0 userInfo:@{NSLocalizedFailureReasonErrorKey: @"Error getting proxy configuration."}];
                self.status = TorXPCServiceStatusError;
                self.lastError = error;
                return;
            }
            
            NSString *socksHost = configuration.connectionProxyDictionary[(NSString*)kCFStreamPropertySOCKSProxyHost];
            uint16_t socksPort = [configuration.connectionProxyDictionary[(NSString*)kCFStreamPropertySOCKSProxyPort] unsignedShortValue];
            

            NSString *hsDir = onionService.serviceDirectory;
            NSString *hostnamePath = [hsDir stringByAppendingPathComponent:@"hostname"];
            NSString *hostname = [NSString stringWithContentsOfFile:hostnamePath encoding:NSUTF8StringEncoding error:&error];
            if (error) {
                self.status = TorXPCServiceStatusError;
                self.lastError = error;
                return;
            }
            self.status = TorXPCServiceStatusReady;
            
            [self.listener circuitReadyWithSocksHost:socksHost socksPort:socksPort hiddenService:hostname];
            
            // Test that it works
            // TODO: remove
            NSURLSession *session = [NSURLSession sessionWithConfiguration:configuration];
            [[session dataTaskWithURL:[NSURL URLWithString:@"https://facebookcorewwwi.onion/"] completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                NSLog(@"Loaded onion!");
                //XCTAssertEqual([(NSHTTPURLResponse *)response statusCode], 200);
                //XCTAssertNil(error);
                //[expectation fulfill];
            }] resume];
        }];
    };
    
    [self.controller authenticateWithData:cookie completion:^(BOOL success, NSError *error) {
        if (!success) {
            self.status = TorXPCServiceStatusError;
            self.lastError = error;
            [self teardown];
            return;
        }
        
        [self.controller addObserverForStatusEvents:^BOOL(NSString * _Nonnull type, NSString * _Nonnull severity, NSString * _Nonnull action, NSDictionary<NSString *,NSString *> * _Nullable arguments) {
            NSLog(@"type: %@ severity: %@ action: %@, args: %@", type, severity, action, arguments);
            return YES;
        }];
        
        [self.controller addObserverForCircuitEstablished:^(BOOL established) {
            if (!established) {
                return;
            }
            circuitEstablished();
        }];
    }];
}
    

@end
