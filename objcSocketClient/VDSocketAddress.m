//
//  VDSocketAddress.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketAddress.h"

@import objcTemp;

static const NSTimeInterval VDSocketAddressDefaultConnectionTimeout = 15;

@interface VDSocketAddress ()


@end


@implementation VDSocketAddress

#pragma mark Constructor
+ (instancetype)emptyAddress {
    return [[self alloc] initWithRemoteIP:nil remotePort:nil connectionTimeout:VDSocketAddressDefaultConnectionTimeout];
}

+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort {
    return [[self alloc] initWithRemoteIP:remoteIP remotePort:remotePort connectionTimeout:VDSocketAddressDefaultConnectionTimeout];
}

+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort connectionTimeout:(NSTimeInterval)connectionTimeout {
    return [[self alloc] initWithRemoteIP:remoteIP remotePort:remotePort connectionTimeout:connectionTimeout];
}

- (instancetype)initWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort connectionTimeout:(NSTimeInterval)connectionTimeout {
    self = [super init];
    
    self.remoteIP = remoteIP;
    self.remotePort = remotePort;
    self.connectionTimeout = connectionTimeout;
    
    return self;
}

#pragma mark Public Method
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

    return self;
}

- (void)dealloc {
    
}


#pragma mark Delegates


#pragma mark Private Method

@end
