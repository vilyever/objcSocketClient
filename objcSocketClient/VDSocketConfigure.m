//
//  VDSocketConfigure.m
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketConfigure.h"


@interface VDSocketConfigure ()


@end


@implementation VDSocketConfigure

#pragma mark Public Method


#pragma mark Properties
- (void)setAddress:(VDSocketAddress *)address {
    _address = [address copy];
}

- (void)setSocketPacketHelper:(VDSocketPacketHelper *)socketPacketHelper {
    _socketPacketHelper = [socketPacketHelper copy];
}

- (void)setHeartBeatHelper:(VDSocketHeartBeatHelper *)heartBeatHelper {
    _heartBeatHelper = [heartBeatHelper copy];
}

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
