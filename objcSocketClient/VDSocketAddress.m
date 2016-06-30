//
//  VDSocketAddress.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketAddress.h"

@import objcTemp;

@interface VDSocketAddress ()


@end


@implementation VDSocketAddress

#pragma mark Public Method
+ (instancetype)emptyAddress {
    return [self addressWithRemoteIP:nil remotePort:nil];
}

+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort {
    return [self addressWithRemoteIP:remoteIP remotePort:remotePort withConnectionTimeout:VDSocketAddressDefaultConnectionTimeout];
}

+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort withConnectionTimeout:(NSInteger)connectionTimeout {
    VDSocketAddress *address = [[self alloc] init];
    address.remoteIP = remoteIP;
    address.remotePort = remotePort;
    address.connectionTimeout = connectionTimeout;
    return address;
}

- (void)checkValidation {
    if (!self.remoteIP || ![self.remoteIP vd_isRegexMatched:VDRegexIP]) {
        NSCAssert(NO, @"we need a correct remote IP to connect");
    }
    
    if (!self.remotePort || ![self.remotePort vd_isRegexMatched:VDRegexPort]) {
        NSCAssert(NO, @"we need a correct remote port to connect");
    }
    
    if (self.connectionTimeout <= 0) {
        NSCAssert(NO, @"we need a connectionTimeout > 0");
    }
}


#pragma mark Properties


#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (void)dealloc {
    
}


#pragma mark Delegates


#pragma mark Private Method
- (void)internalInit {
    
}

@end
