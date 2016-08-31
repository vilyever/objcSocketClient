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

@property (nonatomic, strong) VDSocketHeartBeatHelper *original;

@end


@implementation VDSocketHeartBeatHelper

#pragma mark Public Method
- (NSData *)getSendData {
    if (self.sendDataBuilder) {
        return self.sendDataBuilder();
    }
    
    return self.defaultSendData;
}

- (BOOL)isReceiveHeartBeatPacket:(VDSocketResponsePacket *)packet {
    if (self.isReceiveHeartBeatPacketChecker) {
        return self.isReceiveHeartBeatPacketChecker(packet);
    }
    
    if (self.defaultReceiveData) {
        return [packet isDataEqual:self.defaultReceiveData];
    }
    
    return NO;
}


#pragma mark Properties
- (VDSocketHeartBeatHelper *)original {
    if (!_original) {
        return self;
    }
    
    return _original;
}

- (void)setSendDataBuilder:(NSData *(^)(void))sendDataBuilder {
    _sendDataBuilder = [sendDataBuilder copy];
}

- (void)setReceiveHeartBeatPacketChecker:(BOOL (^)(VDSocketResponsePacket *))isReceiveHeartBeatPacketChecker {
    _isReceiveHeartBeatPacketChecker = isReceiveHeartBeatPacketChecker;
}

- (BOOL)isSendHeartBeatEnabled {
    if ((!self.defaultSendData
            && !self.sendDataBuilder)
        || self.heartBeatInterval <= 0) {
        return NO;
    }
    
    return _sendHeartBeatEnabled;
}

#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    
    return self;
}

- (void)dealloc {
    
}

- (id)copyWithZone:(NSZone *)zone {
    VDSocketHeartBeatHelper *helper = [[VDSocketHeartBeatHelper alloc] init];
    helper.original = self;
    
    helper.defaultSendData = self.defaultSendData;
    helper.sendDataBuilder = self.sendDataBuilder;
    
    helper.defaultReceiveData = self.defaultReceiveData;
    helper.isReceiveHeartBeatPacketChecker = self.isReceiveHeartBeatPacketChecker;

    helper.heartBeatInterval = self.heartBeatInterval;
    helper.sendHeartBeatEnabled = self.sendHeartBeatEnabled;
    
    return helper;
}


#pragma mark Delegates


#pragma mark Private Method

@end
