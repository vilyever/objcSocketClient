//
//  VDSocketHeartBeatHelper.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketHeartBeatHelper.h"


@interface VDSocketHeartBeatHelper ()


@end


@implementation VDSocketHeartBeatHelper

#pragma mark Public Method
- (void)disableHeartBeat {
    self.sendData = nil;
    self.sendMessage = nil;
}

- (void)disableRemoteNoReplyTimeout {
    self.remoteNoReplyAliveTimeout = VDSocketHeartBeatNoneRemoteNoReplyTimeout;
}

- (BOOL)shouldSendHeartBeat {
    return (self.sendData || self.sendMessage) && self.heartBeatInterval != VDSocketHeartBeatNoneInterval;
}

- (BOOL)shouldAutoDisconnectOnRemoteNoReplyTimeout {
	return self.remoteNoReplyAliveTimeout != VDSocketHeartBeatNoneRemoteNoReplyTimeout;
}


#pragma mark Properties
- (NSInteger)heartBeatInterval {
    if (_heartBeatInterval <= 0) {
        return VDSocketHeartBeatNoneInterval;
    }
    
    return _heartBeatInterval;
}

- (NSInteger)remoteNoReplyAliveTimeout {
    if (_remoteNoReplyAliveTimeout <= 0) {
        return VDSocketHeartBeatNoneRemoteNoReplyTimeout;
    }
    
    return _remoteNoReplyAliveTimeout;
}

#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    
    return self;
}

- (void)dealloc {
    
}

- (id)copy {
    VDSocketHeartBeatHelper *helper = [[[self class] alloc] init];
    helper.sendData = self.sendData;
    helper.sendMessage = self.sendMessage;
    helper.receiveData = self.receiveData;
    helper.receiveMessage = self.receiveMessage;
    helper.heartBeatInterval = self.heartBeatInterval;
    helper.remoteNoReplyAliveTimeout = self.remoteNoReplyAliveTimeout;
    return helper;
}


#pragma mark Delegates


#pragma mark Private Method

@end
