//
//  VDSocketPacketHelper.m
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketPacketHelper.h"


@interface VDSocketPacketHelper ()

@property (nonatomic, strong) VDSocketPacketHelper *original;

@end


@implementation VDSocketPacketHelper

#pragma mark Public Method
- (void)checkValidation {
    switch (self.readStrategy) {
        case VDSocketPacketReadStrategyManually: {
            return;
        }
        case VDSocketPacketReadStrategyAutoReadToTrailer: {
            if (self.receiveTrailerData.length == 0) {
                NSCAssert(NO, @"we need ReceiveTrailerData for ReadStrategyAutoReadToTrailer");
            }
            return;
        }
        case VDSocketPacketReadStrategyAutoReadByLength: {
            if (self.receivePacketLengthDataLength <= 0
                || !self.receivePacketDataLengthConvertor) {
                NSCAssert(NO, @"we need receivePacketLengthDataLength > 0 AND receivePacketDataLengthConvertor for ReadStrategyAutoReadByLength");
            }
            return;
        }
    }
    
    NSCAssert(NO, @"we need a correct readStrategy");
}

- (NSData *)getSendPacketLengthDataForPacketLength:(NSInteger)packetLength {
    if (self.sendPacketLengthDataConvertor) {
        return self.sendPacketLengthDataConvertor(packetLength);
    }

    return nil;
}

- (NSInteger)getReceivePacketDataLength:(NSData *)packetLengthData {
    if (self.readStrategy == VDSocketPacketReadStrategyAutoReadByLength) {
        if (self.receivePacketDataLengthConvertor) {
            return self.receivePacketDataLengthConvertor(packetLengthData);
        }
    }
    
    return 0;
}


#pragma mark Properties
- (VDSocketPacketHelper *)original {
    if (!_original) {
        return self;
    }
    
    return _original;
}

- (void)setSendSegmentLength:(NSInteger)sendSegmentLength {
    _sendSegmentLength = sendSegmentLength;
}

- (BOOL)isSendSegmentEnabled {
    if (self.sendSegmentLength <= 0) {
        return NO;
    }
    
    return _sendSegmentEnabled;
}

- (void)setSendPacketLengthDataConvertor:(NSData *(^)(NSInteger))sendPacketLengthDataConvertor {
    _sendPacketLengthDataConvertor = [sendPacketLengthDataConvertor copy];
}

- (void)setReceivePacketDataLengthConvertor:(NSInteger (^)(NSData *))receivePacketDataLengthConvertor {
    _receivePacketDataLengthConvertor = [receivePacketDataLengthConvertor copy];
}

- (void)setReceiveSegmentLength:(NSInteger)receiveSegmentLength {
    _receiveSegmentLength = receiveSegmentLength;
}

- (BOOL)isReceiveSegmentEnabled {
    if (self.receiveSegmentLength <= 0) {
        return NO;
    }
    
    return _receiveSegmentEnabled;
}

#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    
    _readStrategy = VDSocketPacketReadStrategyManually;
    
    return self;
}

- (void)dealloc {
    
}

- (id)copyWithZone:(NSZone *)zone {
    VDSocketPacketHelper *helper = [[VDSocketPacketHelper alloc] init];
    helper.original = self;
        
    helper.sendHeaderData = self.sendHeaderData;
    helper.sendPacketLengthDataConvertor = [self.sendPacketLengthDataConvertor copyWithZone:zone];
    helper.sendTrailerData = self.sendTrailerData;
    helper.sendSegmentLength = self.sendSegmentLength;
    helper.sendSegmentEnabled = self.sendSegmentEnabled;
    
    helper.readStrategy = self.readStrategy;

    helper.receiveHeaderData = self.receiveHeaderData;
    helper.receivePacketLengthDataLength = self.receivePacketLengthDataLength;
    helper.receivePacketDataLengthConvertor = self.receivePacketDataLengthConvertor;
    helper.receiveTrailerData = self.receiveTrailerData;
    helper.receiveSegmentLength = self.receiveSegmentLength;
    helper.receiveSegmentEnabled = self.receiveSegmentEnabled;

    return helper;
}


#pragma mark Delegates


#pragma mark Private Method

@end
