//
//  VDSocketAddress.m
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketAddress.h"
#import <objcString/objcString.h>

static const NSTimeInterval VDSocketAddressDefaultConnectionTimeout = 15;

@interface VDSocketAddress ()

@property (nonatomic, strong) VDSocketAddress *original;

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

- (void)setRemotePortWithInteger:(NSInteger)port {
    self.remotePort = [NSString stringWithFormat:@"%@", @(port)];
}

- (NSInteger)getRemotePortIntegerValue {
    return [self.remotePort integerValue];
}


#pragma mark Properties
- (VDSocketAddress *)original {
    if (!_original) {
        return self;
    }
    
    return _original;
}

#pragma mark Overrides
- (instancetype)init {
    self = [super init];

    return self;
}

- (void)dealloc {
    
}

- (id)copyWithZone:(NSZone *)zone {
    VDSocketAddress *address = [VDSocketAddress addressWithRemoteIP:self.remoteIP remotePort:self.remotePort connectionTimeout:self.connectionTimeout];
    address.original = self;
    
    return address;
}


#pragma mark Delegates


#pragma mark Private Method

@end
