//
//  VDSocketPacketHelper.h
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>

@class VDSocketPacketHelper;

@protocol VDSocketPacketHelperPacketLengthConversionProtocol <NSObject>

@required
- (NSData *)sendPacketLengthDataForPacketLength:(NSInteger)packetLength forSocketPacketHelper:(VDSocketPacketHelper *)helper;
- (NSInteger)receivePacketDataLengthForPacketLengthData:(NSData *)packetLengthData forSocketPacketHelper:(VDSocketPacketHelper *)helper;

@end


@interface VDSocketPacketHelper : NSObject
/**
 *  封包格式
 *  包头（可选） --- 包长度（正文长度+包尾长度，若有包尾此信息可选） --- 正文（包含任意信息，包类型，数据等，必选） --- 包尾（若有包长度此信息可选）
 *  
 *  发送：包头包尾依照此helper设置的值发送，nil表示不发送，包长度由VDSocketPacketHelperHeaderProtocol或block获取（block优先，都无法获取表示不发送）
 *  接收：
 *      按包长度接收：若有包头先确定包头正确，然后读取设定的包长度字节数，由VDSocketPacketHelperHeaderProtocol或block获取（block优先）将字节数组转换为int长度，然后读取此长度信息
 *      按包尾接收：若有包头先确定包头正确，然后一直读取到与包尾相同的字节数组（若正文中含有与包尾相同的字节数组，会导致读取错误）
 */

#pragma mark Public Method
- (void)checkValidation; // （接收包尾） 或 （接收长度，接收长度转换） 必须设置一项，以确保能够正确读取远程数据

- (NSData *)getSendPacketLengthDataForPacketLength:(NSInteger)packetLength;
- (NSInteger)getReceivePacketDataLength:(NSData *)packetLengthData;

/**
 *  是否按包长度读取数据
 *  否表示按包尾分割读取数据
 */
- (BOOL)isReadDataWithPacketLength;

#pragma mark Properties
/**
 *  包头信息接口
 */
@property (nonatomic, weak) id<VDSocketPacketHelperPacketLengthConversionProtocol> packetLengthConversionProtocol;

/**
 *  发送时自动添加的包头
 */
@property (nonatomic, copy) NSData *sendHeaderData;

/**
 *  获取发送包长度对应的data，若此block不为nil，将不会调用protocol中相同功能的方法
 */
@property (nonatomic, copy, setter=setSendPacketLengthDataConvertor:) NSData *(^sendPacketLengthDataConvertor)(NSInteger packetLength);
- (void)setSendPacketLengthDataConvertor:(NSData *(^)(NSInteger packetLength))sendPacketLengthDataConvertor;

/**
 *  发送时自动添加的包尾
 */
@property (nonatomic, copy) NSData *sendTrailerData;

/**
 *  分段发送信息，每段的长度
 *  若设置大于0时，sendSegmentEnabled自动变更为YES，反之亦然
 *  设置后可再次变更sendSegmentEnabled的值
 */
@property (nonatomic, assign) NSInteger sendSegmentLength;
@property (nonatomic, assign, getter=isSendSegmentEnabled) BOOL sendSegmentEnabled; // 若sendSegmentLength<=0,返回NO

/**
 *  是否自动依照下述配置读取信息，默认为YES
 *  若设为NO，需手动调用SocketClient中的方法读取
 */
@property (nonatomic, assign) BOOL autoReceiveEnabled;

/**
 *  接收时每条消息的包头
 */
@property (nonatomic, copy) NSData *receiveHeaderData;

/**
 *  接收时，包长度data的固定字节数
 */
@property (nonatomic, assign) NSInteger receivePacketLengthDataLength;

/**
 *  获取接收包data对应的长度，若此block不为nil，将不会调用protocol中相同功能的方法
 */
@property (nonatomic, copy, setter=setReceivePacketDataLengthConvertor:) NSInteger(^receivePacketDataLengthConvertor)(NSData *packetLengthData);
- (void)setReceivePacketDataLengthConvertor:(NSInteger(^)(NSData *packetLengthData))receivePacketDataLengthConvertor;

/**
 *  接收时每条消息的包尾
 */
@property (nonatomic, copy) NSData *receiveTrailerData;

/**
 *  分段接收信息，每段的长度
 *  若设置大于0时，receiveSegmentEnabled自动变更为YES，反之亦然
 *  设置后可再次变更receiveSegmentEnabled的值
 */
@property (nonatomic, assign) NSInteger receiveSegmentLength;
@property (nonatomic, assign, getter=isReceiveSegmentEnabled) BOOL receiveSegmentEnabled; // 若receiveSegmentLength<=0,返回NO

@end
