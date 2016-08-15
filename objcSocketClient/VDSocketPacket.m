//
//  VDSocketPacket.m
//  objcSocketClient
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
    return [[self alloc] initWithData:data isHeartBeat:YES];
}

- (instancetype)initWithData:(NSData *)data {
    return [self initWithData:data isHeartBeat:NO];
}

- (instancetype)initWithData:(NSData *)data isHeartBeat:(BOOL)isHeartBeat {
    self = [super init];
    
    _ID = AtomicID++;
    _data = data;
    _isHeartBeat = isHeartBeat;
    
    return self;
}

- (instancetype)initWithString:(NSString *)message {
    self = [super init];
    
    _ID = AtomicID++;
    _message = message;
    
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
    
    return self;
}

- (void)dealloc {
    
}


#pragma mark Delegates


#pragma mark Private Method

@end
