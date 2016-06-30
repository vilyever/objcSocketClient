//
//  VDSocketPacketHelper.h
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !VDSocketPacketSegmentLengthMax
#define VDSocketPacketSegmentLengthMax \
(-1)
#endif

@class VDSocketPacketHelper;

@protocol VDSocketPacketHelperHeaderProtocol <NSObject>

@required
- (NSData *)socketHeaderDataFromSendingData:(NSData *)sendingData isHeartBeat:(BOOL)isHeartBeat;
- (NSInteger)socketReceiveHeaderDataLength;
- (NSInteger)socketReceiveBodyDataLengthFromHeaderData:(NSData *)headerData;

@end


@interface VDSocketPacketHelper : NSObject

#pragma mark Public Method
/**
 *  禁用分段发送
 */
- (void)disalbeSegmentSend;

/**
 *  是否分段发送
 *
 *  @return
 */
- (BOOL)shouldSegmentSend;

/**
 *  是否在发送和接收时，都包含包头和正文信息两部份
 *  包头：固定长度，必须含有正文长度信息，也可携带其它如消息类型等信息
 *
 *  @return
 */
- (BOOL)isDataWithHeader;

- (NSData *)getSendHeaderDataWithSendingData:(NSData *)sendingData isHeartBeat:(BOOL)isHeartBeat;
- (NSInteger)getReceiveHeaderDataLength;
- (NSInteger)getReceiveBodyDataLengthWithHeaderData:(NSData *)headerData;

- (void)setSendHeaderDataBlock:(NSData *(^)(NSData *data, BOOL isHeartBeat))sendHeaderDataBlock;
- (void)setReceiveBodyDataLengthBlock:(NSInteger(^)(NSData *headerData))receiveBodyDataLengthBlock;

#pragma mark Properties
/**
 *  发送时自动添加的包尾
 *  设置STRING会自动转化为byte，编码由VDSocketClient提供
 *  若@selector(isDataWithHeader)返回YES，将不会发送包尾
 */
@property (nonatomic, strong) NSData *sendTrailerData;
@property (nonatomic, copy) NSString *sendTrailerMessage;

/**
 *  接收时分离每条消息的包尾，返回数据时会自动删除
 *  设置STRING会自动转化为byte，编码由VDSocketClient提供
 *  若@selector(isDataWithHeader)返回YES，将不会依照此属性分离消息
 */
@property (nonatomic, strong) NSData *receiveTrailerData;
@property (nonatomic, copy) NSString *receiveTrailerMessage;

/**
 *  分段发送信息，每段的长度
 *  若不大于0表示不分段
 */
@property (nonatomic, assign) NSInteger sendSegmentLength;

/**
 *  以下属性为发送接收时以 包头（固定长度）-> 正文（包头信息中的长度）-> 包头（固定长度）-> 正文（包头信息中的长度）-> 包头（固定长度）-> 正文（包头信息中的长度）...
 *  方式发送，忽略以上设置的包尾
 *  注意：以下三个属性全设置才有效(或设置VDSocketPacketHelperHeaderProtocol, 优先使用protocol)
 */

/**
 *  求解发送时的包头信息，因为自动发送的心跳包也需要包头信息，所以通过此block统一发送
 */
@property (nonatomic, copy, setter=setSendHeaderDataBlock:) NSData *(^sendHeaderDataBlock)(NSData *sendingData, BOOL isHeartBeat);

/**
 *  接收时，包头的固定长度：先接收包头，得知正文长度后再接收正文
 */
@property (nonatomic, assign) NSInteger receiveHeaderDataLength;
/**
 *  求解包头中携带的正文长度信息
 */
@property (nonatomic, copy, setter=setReceiveBodyDataLengthBlock:) NSInteger(^receiveBodyDataLengthBlock)(NSData *headerData);

/**
 *  包头信息接口
 */
@property (nonatomic, weak) id<VDSocketPacketHelperHeaderProtocol> headerProtocol;

@end
