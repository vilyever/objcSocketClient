//
//  VDSocketPacketHelper.h
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, VDSocketPacketReadStrategy) {
    /**
     *  手动读取
     *  手动调用VDSocketClient的read方法读取信息
     */
    VDSocketPacketReadStrategyManually,
    /**
     *  自动读取到包尾，需设置接收包尾数据receiveTrailerData
     *  自动读取信息直到读取到与包尾相同的数据后，回调接收包
     */
    VDSocketPacketReadStrategyAutoReadToTrailer,
    /**
     *  自动按长度读取，需设置接收时的包长度信息的字节长度receivePacketLengthDataLength和包长度转换器receivePacketDataLengthConvertor
     *  自动读取receivePacketLengthDataLength长度的信息，通过包长度转换器receivePacketDataLengthConvertor获取余下的信息包的长度，然后读取，回调接收包
     */
    VDSocketPacketReadStrategyAutoReadByLength,
};

@class VDSocketPacketHelper;


@interface VDSocketPacketHelper : NSObject <NSCopying>
/**
 *  封包格式
 *  包头（可选） --- 包长度（正文长度+包尾长度，若有包尾此信息可选） --- 正文（包含任意信息，包类型，数据等，必选） --- 包尾（若有包长度此信息可选）
 *  
 *  发送：包头包尾依照此helper设置的值发送，nil表示不发送，包长度data由sendPacketLengthDataConvertor获取
 *  接收：
 *      按包长度接收：若有包头先确定包头正确，然后读取设定的包长度字节数，由receivePacketDataLengthConvertor将字节数组转换为int长度，然后读取此长度信息
 *      按包尾接收：若有包头先确定包头正确，然后一直读取到与包尾相同的字节数组（若正文中含有与包尾相同的字节数组，会导致读取错误）
 */

#pragma mark Public Method
- (void)checkValidation; // 检查readStrategy所必需的数据是否设置

- (NSData *)getSendPacketLengthDataForPacketLength:(NSInteger)packetLength;
- (NSInteger)getReceivePacketDataLength:(NSData *)packetLengthData;

#pragma mark Properties
/**
 *  发送时自动添加的包头
 */
@property (nonatomic, copy) NSData *sendHeaderData;

/**
 *  获取发送包长度对应的data
 */
@property (nonatomic, copy, setter=setSendPacketLengthDataConvertor:) NSData *(^sendPacketLengthDataConvertor)(NSInteger packetLength);
- (void)setSendPacketLengthDataConvertor:(NSData *(^)(NSInteger packetLength))sendPacketLengthDataConvertor;

/**
 *  发送时自动添加的包尾
 */
@property (nonatomic, copy) NSData *sendTrailerData;

/**
 *  分段发送信息，每段的长度
 *  不大于0表示不分段
 */
@property (nonatomic, assign) NSInteger sendSegmentLength;
/**
 *  是否分段发送
 *  若sendSegmentLength<=0,返回NO
 *  默认为NO
 */
@property (nonatomic, assign, getter=isSendSegmentEnabled) BOOL sendSegmentEnabled;

/**
 * 发送超时时长，超过时长无法写出自动断开连接
 * 仅在每个发送包开始发送时计时，结束后重置计时
 */
@property (nonatomic, assign) NSTimeInterval sendTimeout;
@property (nonatomic, assign, getter=isSendTimeoutEnabled) BOOL sendTimeoutEnabled;

/**
 *  读取策略
 *  默认为VDSocketPacketReadStrategyManually
 */
@property (nonatomic, assign) VDSocketPacketReadStrategy readStrategy;

/**
 *  接收时每条消息的包头
 */
@property (nonatomic, copy) NSData *receiveHeaderData;

/**
 *  接收时，包长度data的固定字节数
 */
@property (nonatomic, assign) NSInteger receivePacketLengthDataLength;

/**
 *  获取接收包data对应的长度
 */
@property (nonatomic, copy, setter=setReceivePacketDataLengthConvertor:) NSInteger(^receivePacketDataLengthConvertor)(NSData *packetLengthData);
- (void)setReceivePacketDataLengthConvertor:(NSInteger(^)(NSData *packetLengthData))receivePacketDataLengthConvertor;

/**
 *  接收时每条消息的包尾
 */
@property (nonatomic, copy) NSData *receiveTrailerData;

/**
 *  分段接收信息，每段的长度, 仅在按长度读取时有效
 */
@property (nonatomic, assign) NSInteger receiveSegmentLength;
/**
 *  是否分段读取
 *  若receiveSegmentLength<=0,返回NO
 *  默认为NO
 */
@property (nonatomic, assign, getter=isReceiveSegmentEnabled) BOOL receiveSegmentEnabled;

/**
 * 读取超时时长，超过时长没有读取到任何消息自动断开连接
 */
@property (nonatomic, assign) NSTimeInterval receiveTimeout;
@property (nonatomic, assign, getter=isReceiveTimeoutEnabled) BOOL receiveTimeoutEnabled;

@end
