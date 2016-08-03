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
@property (nonatomic, copy, readwrite) NSData *data;
@property (nonatomic, copy, readwrite) NSString *message;
@property (nonatomic, assign, readwrite) BOOL isHeartBeat;

@end


@implementation VDSocketPacket

#pragma mark Constructor
+ (instancetype)packetWithData:(NSData *)data {
    return [[self alloc] initWithData:data];
}

+ (instancetype)packetWithString:(NSString *)message {
    return [[self alloc] initWithString:message];
}

+ (instancetype)heartBeatPacketWithData:(NSData *)data {
    return [[self alloc] initHeartBeatPacketWithData:data];
}

- (instancetype)initWithData:(NSData *)data {
    self = [super init];
    
    self.data = data;
    
    return self;
}

- (instancetype)initWithString:(NSString *)message {
    self = [super init];
    
    self.message = message;
    
    return self;
}

- (instancetype)initHeartBeatPacketWithData:(NSData *)data {
    self = [super init];
    
    self.data = data;
    self.isHeartBeat = YES;
    
    return self;
}

#pragma mark Public Method
- (void)buildDataWithEncoding:(NSStringEncoding)encoding {
    if (self.message) {
        self.data = [self.message dataUsingEncoding:encoding];
    }
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
