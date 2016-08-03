//
//  VDSocketHeartBeatHelper.h
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VDSocketResponsePacket.h"

@class VDSocketHeartBeatHelper;

@protocol VDSocketHeartBeatHelperProtocol <NSObject>

@required
- (NSData *)sendHeartBeatDataForSocketHeartBeatHelper:(VDSocketHeartBeatHelper *)helper; // doing on background thread
- (BOOL)isReceiveHeartBeatPacket:(VDSocketResponsePacket *)packet forSocketHeartBeatHelper:(VDSocketHeartBeatHelper *)helper; // doing on background thread

@end


@interface VDSocketHeartBeatHelper : NSObject

#pragma mark Public Method
- (NSData *)getSendData;
- (BOOL)isReceiveHeartBeatPacket:(VDSocketResponsePacket *)packet;

#pragma mark Properties
@property (nonatomic, weak) id<VDSocketHeartBeatHelperProtocol> protocol;

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
@property (nonatomic, copy, setter=setIsReceiveHeartBeatPacketChecker:) BOOL(^isReceiveHeartBeatPacketChecker)(VDSocketResponsePacket *packet);
- (void)setIsReceiveHeartBeatPacketChecker:(BOOL (^)(VDSocketResponsePacket *packet))isReceiveHeartBeatPacketChecker;

/**
 *  发送心跳包的间隔
 */
@property (nonatomic, assign) NSTimeInterval heartBeatInterval;

/**
 *  是否发送心跳包
 *  设置defaultSendData不为nil，自动变更为YES
 *  设置sendDataBuilderBlock不为nil，自动变更为YES
 *  设置protocol不为nil，自动变更为YES
 *  
 *  自动变更后可手动设置
 *  上述三者皆为nil，返回NO
 */
@property (nonatomic, assign) BOOL sendHeartBeatEnabled;

/**
 *  若远程端在此时长内都没有发送信息到本地，自动断开连接
 *  若设置大于0时，autoDisconnectOnRemoteNoReplyAliveTimeout自动变更为YES，反之亦然
 *  设置后可再次变更autoDisconnectOnRemoteNoReplyAliveTimeout的值
 */
@property (nonatomic, assign) NSTimeInterval remoteNoReplyAliveTimeout;
@property (nonatomic, assign) BOOL autoDisconnectOnRemoteNoReplyAliveTimeout; // 若remoteNoReplyAliveTimeout<=0,返回NO

@end
