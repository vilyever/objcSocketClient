//
//  VDSocketPacket.h
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VDSocketPacket;


@interface VDSocketPacket : NSObject

#pragma mark Public Method
+ (instancetype)packetWithData:(NSData *)data;
+ (instancetype)packetWithString:(NSString *)message;

#pragma mark Properties
/**
 *  唯一
 */
@property (nonatomic, assign, readonly) NSInteger ID;
@property (nonatomic, strong, readonly) NSData *data;
@property (nonatomic, copy, readonly) NSString *message;
//@property (nonatomic, assign) BOOL canceled;

@end
