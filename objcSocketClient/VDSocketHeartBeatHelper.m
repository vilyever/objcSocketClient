//
//  VDSocketHeartBeatHelper.m
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketHeartBeatHelper.h"

//static const NSTimeInterval VDSocketHeartBeatDefaultInterval = 30;
//static const NSTimeInterval VDSocketHeartBeatDefaultRemoteNoReplyTimeout = VDSocketHeartBeatDefaultInterval * 2;

@interface VDSocketHeartBeatHelper ()


@end


@implementation VDSocketHeartBeatHelper

#pragma mark Public Method
- (NSData *)getSendData {
    if (self.sendDataBuilder) {
        return self.sendDataBuilder();
    }
    
    if (self.protocol && [self.protocol respondsToSelector:@selector(sendHeartBeatDataForSocketHeartBeatHelper:)]) {
        return [self.protocol sendHeartBeatDataForSocketHeartBeatHelper:self];
    }
    
    return self.defaultSendData;
}

- (BOOL)isReceiveHeartBeatPacket:(VDSocketResponsePacket *)packet {
    if (self.isReceiveHeartBeatPacketChecker) {
        return self.isReceiveHeartBeatPacketChecker(packet);
    }
    
    if (self.protocol && [self.protocol respondsToSelector:@selector(isReceiveHeartBeatPacket:forSocketHeartBeatHelper:)]) {
        return [self.protocol isReceiveHeartBeatPacket:packet forSocketHeartBeatHelper:self];
    }
    
    if (self.defaultReceiveData) {
        return [packet isDataEqual:self.defaultReceiveData];
    }
    
    return NO;
}


#pragma mark Properties
- (void)setProtocol:(id<VDSocketHeartBeatHelperProtocol>)protocol {
    _protocol = protocol;
    if (_protocol) {
        self.sendHeartBeatEnabled = YES;
    }
}

- (void)setDefaultSendData:(NSData *)defaultSendData {
    _defaultSendData = [defaultSendData copy];
    if (_defaultSendData) {
        self.sendHeartBeatEnabled = YES;
    }
}

- (void)setSendDataBuilder:(NSData *(^)(void))sendDataBuilder {
    _sendDataBuilder = [sendDataBuilder copy];
    if (_sendDataBuilder) {
        self.sendHeartBeatEnabled = YES;
    }
}

- (void)setReceiveHeartBeatPacketChecker:(BOOL (^)(VDSocketResponsePacket *))isReceiveHeartBeatPacketChecker {
    _isReceiveHeartBeatPacketChecker = isReceiveHeartBeatPacketChecker;
}

- (void)setHeartBeatInterval:(NSTimeInterval)heartBeatInterval {
    _heartBeatInterval = heartBeatInterval;
    if (_heartBeatInterval > 0) {
        self.sendHeartBeatEnabled = YES;
    }
}

- (BOOL)isSendHeartBeatEnabled {
    if ((!self.protocol
            && !self.defaultSendData
            && !self.sendDataBuilder)
        || self.heartBeatInterval <= 0) {
        return NO;
    }
    
    return _sendHeartBeatEnabled;
}

- (void)setRemoteNoReplyAliveTimeout:(NSTimeInterval)remoteNoReplyAliveTimeout {
    _remoteNoReplyAliveTimeout = remoteNoReplyAliveTimeout;
    if (_remoteNoReplyAliveTimeout > 0) {
        self.autoDisconnectOnRemoteNoReplyAliveTimeout = YES;
    }
}

- (BOOL)isAutoDisconnectOnRemoteNoReplyAliveTimeout {
    if (self.remoteNoReplyAliveTimeout <= 0) {
        return NO;
    }
    
    return _autoDisconnectOnRemoteNoReplyAliveTimeout;
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
    helper.protocol = self.protocol;
    
    helper.defaultSendData = [self.defaultSendData copy];
    helper.sendDataBuilder = [self.sendDataBuilder copy];
    
    helper.defaultReceiveData = [self.defaultReceiveData copy];
    helper.isReceiveHeartBeatPacketChecker = [self.isReceiveHeartBeatPacketChecker copy];

    helper.heartBeatInterval = self.heartBeatInterval;
    helper.sendHeartBeatEnabled = self.sendHeartBeatEnabled;
    
    helper.remoteNoReplyAliveTimeout = self.remoteNoReplyAliveTimeout;
    helper.autoDisconnectOnRemoteNoReplyAliveTimeout = self.autoDisconnectOnRemoteNoReplyAliveTimeout;
    
    return helper;
}


#pragma mark Delegates


#pragma mark Private Method

@end
