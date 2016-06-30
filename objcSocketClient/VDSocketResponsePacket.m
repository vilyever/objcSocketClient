//
//  VDSocketResponsePacket.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketResponsePacket.h"


@interface VDSocketResponsePacket ()

@property (nonatomic, strong, readwrite) NSData *headerData;
@property (nonatomic, strong, readwrite) NSData *data;
//@property (nonatomic, copy, readwrite) NSString *message;

@end


@implementation VDSocketResponsePacket

#pragma mark Public Method
+ (instancetype)packetWithHeaderData:(NSData *)headerData bodyData:(NSData *)data {
    VDSocketResponsePacket *packet = [[self alloc] init];
    packet.headerData = headerData;
    packet.data = data;
    return packet;
}

+ (instancetype)packetWithData:(NSData *)data {
    return [self packetWithHeaderData:nil bodyData:data];
}

//+ (instancetype)packetWithData:(NSData *)data withString:(NSString *)message {
//    VDSocketResponsePacket *packet = [[self alloc] init];
//    packet.data = data;
//    packet.message = message;
//    return packet;
//}

- (BOOL)isMatchData:(NSData *)data {
    return [data isEqualToData:self.data];
}

//- (BOOL)isMatchString:(NSString *)message {
//    return [message isEqualToString:self.message];
//}

#pragma mark Properties


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


#pragma mark Delegates


#pragma mark Private Method
- (void)internalInit {
    
}

@end
