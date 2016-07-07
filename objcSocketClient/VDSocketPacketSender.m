//
//  VDSocketPacketSender.m
//  objcSocketClient
//
//  Created by Deng on 16/6/29.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketPacketSender.h"


@interface VDSocketPacketSender ()

@property (nonatomic, strong, readwrite) VDSocketPacket *packet;

@property (nonatomic, assign) BOOL isHeaderSended;
@property (nonatomic, assign) BOOL isTrailerSended;
@property (nonatomic, assign) NSInteger sendedLength;

@end


@implementation VDSocketPacketSender

#pragma mark Public Method
+ (instancetype)senderWithPacket:(VDSocketPacket *)packet {
    VDSocketPacketSender *sender = [[self alloc] init];
    sender.packet = packet;
    return sender;
}

- (float)getProgressOnNextSended:(VDSocketPacketHelper *)helper {
    if ([helper isDataWithHeader] && !self.isHeaderSended) {
        self.isHeaderSended = YES;
        return 0.01f;
    }
    
    float progress = 1.0f;
    if ([helper shouldSegmentSend]) {
        if (self.sendedLength < self.packet.data.length) {
            self.sendedLength += helper.sendSegmentLength;
            self.sendedLength = MIN(self.sendedLength, self.packet.data.length);

            progress = self.sendedLength / (float)self.packet.data.length;
        }
    }
    
    if (progress == 1.0f) {
        if (![helper isDataWithHeader]) {
            if (!self.isTrailerSended && helper.sendTrailerData) {
                self.isTrailerSended = YES;
                return 0.99f;
            }
        }
    }
    
    return progress;
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
