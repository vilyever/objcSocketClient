//
//  VDSocketResponsePacket.h
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VDSocketResponsePacket;


@interface VDSocketResponsePacket : NSObject

#pragma mark Constructor
+ (instancetype)packet;

#pragma mark Public Method
- (BOOL)isDataEqual:(NSData *)data;
- (void)buildStringWithEncoding:(NSStringEncoding)encoding; // for auto encode message background

#pragma mark Properties
/**
 *  正文信息
 */
@property (nonatomic, strong) NSMutableData *data;
@property (nonatomic, copy) NSString *message;

@property (nonatomic, copy) NSData *headerData;
@property (nonatomic, copy) NSData *packetLengthData;
@property (nonatomic, copy) NSData *trailerData;

@property (nonatomic, assign) BOOL isHeartBeat;

@end
