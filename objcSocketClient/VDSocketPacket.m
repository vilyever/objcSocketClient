//
//  VDSocketPacket.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketPacket.h"

static NSInteger AtomicID = 0;

@interface VDSocketPacket ()

@property (nonatomic, assign, readwrite) NSInteger ID;
@property (nonatomic, strong, readwrite) NSData *data;
@property (nonatomic, copy, readwrite) NSString *message;

@end


@implementation VDSocketPacket

#pragma mark Public Method
+ (instancetype)packetWithData:(NSData *)data {
    VDSocketPacket *packet = [[self alloc] init];
    packet.data = data;
    return packet;
}

+ (instancetype)packetWithString:(NSString *)message {
    VDSocketPacket *packet = [[self alloc] init];
    packet.message = message;
    return packet;
}

#pragma mark Properties


#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    
    _ID = AtomicID++;
    
    return self;
}

- (void)dealloc {
    
}


#pragma mark Delegates


#pragma mark Private Method

@end
