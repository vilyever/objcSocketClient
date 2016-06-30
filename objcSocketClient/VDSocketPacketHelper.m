//
//  VDSocketPacketHelper.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketPacketHelper.h"


@interface VDSocketPacketHelper ()

@end


@implementation VDSocketPacketHelper

#pragma mark Public Method
- (void)disalbeSegmentSend {
    self.sendSegmentLength = VDSocketPacketSegmentLengthMax;
}

- (BOOL)shouldSegmentSend {
    return self.sendSegmentLength != VDSocketPacketSegmentLengthMax;
}

- (BOOL)isDataWithHeader {
    return self.headerProtocol || (self.sendHeaderDataBlock && self.receiveBodyDataLengthBlock && self.receiveHeaderDataLength > 0);
}

- (NSData *)getSendHeaderDataWithSendingData:(NSData *)sendingData isHeartBeat:(BOOL)isHeartBeat {
    if (self.headerProtocol && [self.headerProtocol respondsToSelector:@selector(socketHeaderDataFromSendingData:isHeartBeat:)]) {
        return [self.headerProtocol socketHeaderDataFromSendingData:sendingData isHeartBeat:isHeartBeat];
    }
    
    if (self.sendHeaderDataBlock) {
        return self.sendHeaderDataBlock(sendingData, isHeartBeat);
    }
    
    return nil;
}

- (NSInteger)getReceiveHeaderDataLength {
    if (self.headerProtocol && [self.headerProtocol respondsToSelector:@selector(socketReceiveHeaderDataLength)]) {
        return [self.headerProtocol socketReceiveHeaderDataLength];
    }
    
    return self.receiveHeaderDataLength;
}

- (NSInteger)getReceiveBodyDataLengthWithHeaderData:(NSData *)headerData {
    if (self.headerProtocol && [self.headerProtocol respondsToSelector:@selector(socketReceiveBodyDataLengthFromHeaderData:)]) {
        return [self.headerProtocol socketReceiveBodyDataLengthFromHeaderData:headerData];
    }
    
    if (self.receiveBodyDataLengthBlock) {
        return self.receiveBodyDataLengthBlock(headerData);
    }
    
    return 0;
}


#pragma mark Properties
- (NSData *)sendTrailerData {
    if ([self isDataWithHeader]) {
        return nil;
    }
    return _sendTrailerData;
}

- (NSData *)receiveTrailerData {
    if ([self isDataWithHeader]) {
        return nil;
    }
    return _receiveTrailerData;
}

- (NSInteger)sendSegmentLength {
    if (_sendSegmentLength <= 0) {
        return VDSocketPacketSegmentLengthMax;
    }
    
    return _sendSegmentLength;
}

- (void)setSendHeaderDataBlock:(NSData *(^)(NSData *data, BOOL isHeartBeat))sendHeaderDataBlock {
    _sendHeaderDataBlock = sendHeaderDataBlock;
}

- (void)setReceiveBodyDataLengthBlock:(NSInteger(^)(NSData *headerData))receiveBodyDataLengthBlock {
    _receiveBodyDataLengthBlock = receiveBodyDataLengthBlock;
}

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

- (id)copy {
    VDSocketPacketHelper *packetHelper = [[[self class] alloc] init];
    packetHelper.sendTrailerData = self.sendTrailerData;
    packetHelper.sendTrailerMessage = self.sendTrailerMessage;
    packetHelper.receiveTrailerData = self.receiveTrailerData;
    packetHelper.receiveTrailerMessage = self.receiveTrailerMessage;
    packetHelper.sendSegmentLength = self.sendSegmentLength;
    packetHelper.sendHeaderDataBlock = self.sendHeaderDataBlock;
    packetHelper.receiveHeaderDataLength = self.receiveHeaderDataLength;
    packetHelper.receiveBodyDataLengthBlock = self.receiveBodyDataLengthBlock;
    packetHelper.headerProtocol = self.headerProtocol;
    return packetHelper;
}


#pragma mark Delegates


#pragma mark Private Method
- (void)internalInit {
    
}

@end
