//
//  VDSocketPacket.h
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VDSocketPacket;


@interface VDSocketPacket : NSObject

#pragma mark Constructor
+ (instancetype)packetWithData:(NSData *)data;
+ (instancetype)packetWithString:(NSString *)message;
+ (instancetype)heartBeatPacketWithData:(NSData *)data;

- (instancetype)initWithData:(NSData *)data;
- (instancetype)initWithString:(NSString *)message;
- (instancetype)initHeartBeatPacketWithData:(NSData *)data;

#pragma mark Public Method
- (void)buildDataWithEncoding:(NSStringEncoding)encoding; // for string packet

#pragma mark Properties
@property (nonatomic, assign, readonly) NSInteger ID; // 唯一
@property (nonatomic, copy, readonly) NSData *data;
@property (nonatomic, copy, readonly) NSString *message;
@property (nonatomic, assign, readonly) BOOL isHeartBeat;

@property (nonatomic, copy) NSData *headerData;
@property (nonatomic, copy) NSData *packetLengthData;
@property (nonatomic, copy) NSData *trailerData;

@end
