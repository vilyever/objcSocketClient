//
//  VDSocketResponsePacket.h
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VDSocketResponsePacket;


@interface VDSocketResponsePacket : NSObject

#pragma mark Public Method
+ (instancetype)packetWithHeaderData:(NSData *)headerData bodyData:(NSData *)data;
+ (instancetype)packetWithData:(NSData *)data;
//+ (instancetype)packetWithData:(NSData *)data withString:(NSString *)message;

- (BOOL)isMatchData:(NSData *)data;
//- (BOOL)isMatchString:(NSString *)message;

#pragma mark Properties
/**
 *  包头信息，根据设置可能为nil
 */
@property (nonatomic, strong, readonly) NSData *headerData;

/**
 *  正文信息
 */
@property (nonatomic, strong, readonly) NSData *data;
//@property (nonatomic, copy, readonly) NSString *message;

@end
