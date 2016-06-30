//
//  VDSocketPacketSender.h
//  objcSocketClient
//
//  Created by Deng on 16/6/29.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VDSocketPacket.h"
#import "VDSocketPacketHelper.h"

@class VDSocketPacketSender;


@interface VDSocketPacketSender : NSObject

#pragma mark Public Method
+ (instancetype)senderWithPacket:(VDSocketPacket *)packet;

/**
 *  求解当前发送进度
 *  依据预设的算法，可改进
 *
 *  @param helper 当前使用的PacketHelper，判断是否有包尾，分段等
 *
 *  @return 发送进度0.0f-1.0f
 */
- (float)getProgressOnNextSended:(VDSocketPacketHelper *)helper;

#pragma mark Properties
@property (nonatomic, strong, readonly) VDSocketPacket *packet;

@end
