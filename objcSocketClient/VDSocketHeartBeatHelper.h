//
//  VDSocketHeartBeatHelper.h
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VDSocketResponsePacket.h"

@class VDSocketHeartBeatHelper;


@interface VDSocketHeartBeatHelper : NSObject <NSCopying>

#pragma mark Public Method
- (NSData *)getSendData;
- (BOOL)isReceiveHeartBeatPacket:(VDSocketResponsePacket *)packet;

#pragma mark Properties
/**
 *  默认发送时不变的心跳包数据
 */
@property (nonatomic, copy) NSData *defaultSendData;

/**
 *  发送时可变心跳包数据生成block
 */
@property (nonatomic, copy, setter=setSendDataBuilder:) NSData *(^sendDataBuilder)(void);
- (void)setSendDataBuilder:(NSData *(^)(void))sendDataBuilder;

/**
 *  默认接收时不变的心跳包数据
 */
@property (nonatomic, copy) NSData *defaultReceiveData;

/**
 *  接收时判断可变心跳包数据block
 */
@property (nonatomic, copy, setter=setReceiveHeartBeatPacketChecker:) BOOL(^isReceiveHeartBeatPacketChecker)(VDSocketResponsePacket *packet);
- (void)setReceiveHeartBeatPacketChecker:(BOOL (^)(VDSocketResponsePacket *packet))isReceiveHeartBeatPacketChecker;

/**
 *  发送心跳包的间隔
 */
@property (nonatomic, assign) NSTimeInterval heartBeatInterval;

/**
 *  是否发送心跳包
 *  若没有设置发送数据，返回NO
 *  若heartBeatInterval不大于0，返回NO
 *  默认为NO
 */
@property (nonatomic, assign, getter=isSendHeartBeatEnabled) BOOL sendHeartBeatEnabled;

@end
