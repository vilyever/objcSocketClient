//
//  VDSocketPacketHelper.m
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketPacketHelper.h"


@interface VDSocketPacketHelper ()

@end


@implementation VDSocketPacketHelper

#pragma mark Public Method
- (void)checkValidation {
    if (self.receivePacketLengthDataLength > 0) {
        if (self.receivePacketDataLengthConvertor) {
            return;
        }
        else if (self.packetLengthConversionProtocol && [self.packetLengthConversionProtocol respondsToSelector:@selector(receivePacketDataLengthForPacketLengthData:forSocketPacketHelper:)]) {
            return;
        }
        
        NSCAssert(NO, @"we need receivePacketDataLengthConvertor or packetLengthConversionProtocol since the receivePacketLengthDataLength > 0");
    }
    
    if (self.receiveTrailerData) {
        return;
    }
    
    NSCAssert(NO, @"we need receiveTrailerData or receivePacketLengthDataLength");
}

- (NSData *)getSendPacketLengthDataForPacketLength:(NSInteger)packetLength {
    if (self.sendPacketLengthDataConvertor) {
        return self.sendPacketLengthDataConvertor(packetLength);
    }
    
    if (self.packetLengthConversionProtocol && [self.packetLengthConversionProtocol respondsToSelector:@selector(sendPacketLengthDataForPacketLength:forSocketPacketHelper:)]) {
        return [self.packetLengthConversionProtocol sendPacketLengthDataForPacketLength:packetLength forSocketPacketHelper:self];
    }
    
    return nil;
}

- (NSInteger)getReceivePacketDataLength:(NSData *)packetLengthData {
    if (self.receivePacketDataLengthConvertor) {
        return self.receivePacketDataLengthConvertor(packetLengthData);
    }
    
    if (self.packetLengthConversionProtocol && [self.packetLengthConversionProtocol respondsToSelector:@selector(receivePacketDataLengthForPacketLengthData:forSocketPacketHelper:)]) {
        return [self.packetLengthConversionProtocol receivePacketDataLengthForPacketLengthData:packetLengthData forSocketPacketHelper:self];
    }
    
    return 0;
}

- (BOOL)isReadDataWithPacketLength {
    if (self.receivePacketLengthDataLength > 0) {
        if (self.receivePacketDataLengthConvertor) {
            return YES;
        }
        else if (self.packetLengthConversionProtocol && [self.packetLengthConversionProtocol respondsToSelector:@selector(receivePacketDataLengthForPacketLengthData:forSocketPacketHelper:)]) {
            return YES;
        }
    }
    
    return NO;
}

#pragma mark Properties
- (void)setSendSegmentLength:(NSInteger)sendSegmentLength {
    _sendSegmentLength = sendSegmentLength;
    if (_sendSegmentLength <= 0) {
        self.sendSegmentEnabled = NO;
    }
    else {
        self.sendSegmentEnabled = YES;
    }
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

#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    
    return self;
}

- (void)dealloc {
    
}

- (id)copy {
    VDSocketPacketHelper *packetHelper = [[[self class] alloc] init];
    packetHelper.packetLengthConversionProtocol = self.packetLengthConversionProtocol;
    
    packetHelper.sendHeaderData = [self.sendHeaderData copy];
    packetHelper.sendPacketLengthDataConvertor = [self.sendPacketLengthDataConvertor copy];
    packetHelper.sendTrailerData = [self.sendTrailerData copy];
    packetHelper.sendSegmentLength = self.sendSegmentLength;
    packetHelper.sendSegmentEnabled = self.sendSegmentEnabled;
    
    packetHelper.receiveHeaderData = [self.receiveHeaderData copy];
    packetHelper.receivePacketLengthDataLength = self.receivePacketLengthDataLength;
    packetHelper.receivePacketDataLengthConvertor = [self.receivePacketDataLengthConvertor copy];
    packetHelper.receiveTrailerData = [self.receiveTrailerData copy];
    
    return packetHelper;
}


#pragma mark Delegates


#pragma mark Private Method

@end
