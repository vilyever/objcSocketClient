//
//  VDSocketClient.h
//  objcSocketClient
//
//  Created by Deng on 16/6/27.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VDSocketPacket.h"
#import "VDSocketResponsePacket.h"
#import "VDSocketPacketHelper.h"
#import "VDSocketHeartBeatHelper.h"
#import "VDSocketConfigure.h"
#import "VDSocketAddress.h"

typedef NS_ENUM(NSInteger, VDSocketClientState) {
    VDSocketClientStateDisconnected,
    VDSocketClientStateConnecting,
    VDSocketClientStateConnected
};

static const NSInteger NoneEncodingType = -1;

@class VDSocketClient;

@protocol VDSocketClientDelegate <NSObject>

@optional
- (void)socketClientDidConnected:(VDSocketClient *)client;
- (void)socketClientDidDisconnected:(VDSocketClient *)client;
- (void)socketClient:(VDSocketClient *)client didReceiveResponse:(VDSocketResponsePacket *)packet;
- (void)socketClient:(VDSocketClient *)client didChangeState:(VDSocketClientState)state;

@end

@protocol VDSocketClientSendingDelegate <NSObject>

@optional
- (void)socketClient:(VDSocketClient *)client didBeginSending:(VDSocketPacket *)packet;
- (void)socketClient:(VDSocketClient *)client didEndSending:(VDSocketPacket *)packet;
- (void)socketClient:(VDSocketClient *)client didCancelSending:(VDSocketPacket *)packet;
- (void)socketClient:(VDSocketClient *)client sendingPacket:(VDSocketPacket *)packet withSendedLength:(NSInteger)sendedLength progress:(float)progress;

@end

@protocol VDSocketClientReceivingDelegate <NSObject>

@optional
- (void)socketClient:(VDSocketClient *)client didBeginReceiving:(VDSocketResponsePacket *)packet;
- (void)socketClient:(VDSocketClient *)client didEndReceiving:(VDSocketResponsePacket *)packet;
- (void)socketClient:(VDSocketClient *)client didCancelReceiving:(VDSocketResponsePacket *)packet;
- (void)socketClient:(VDSocketClient *)client receivingResponsePacket:(VDSocketResponsePacket *)packet withReceivedLength:(NSInteger)receivedLength progress:(float)progress;

@end

@interface VDSocketClient : NSObject

#pragma mark Public Method
- (instancetype)initWithAddress:(VDSocketAddress *)address;

- (void)connect;
- (void)disconnect;

- (BOOL)isConnected;
- (BOOL)isConnecting;
- (BOOL)isDisconnected;

- (VDSocketPacket *)sendData:(NSData *)data;
- (VDSocketPacket *)sendString:(NSString *)message;
- (void)sendPacket:(VDSocketPacket *)packet;
- (void)cancelSend:(VDSocketPacket *)packet;

- (VDSocketResponsePacket *)readDataToLength:(NSInteger)length;
- (VDSocketResponsePacket *)readDataToData:(NSData *)data;

- (void)registerSocketClientDelegate:(id<VDSocketClientDelegate>)delegate;
- (void)registerWeakSocketClientDelegate:(id<VDSocketClientDelegate>)delegate;
- (void)removeSocketClientDelegate:(id<VDSocketClientDelegate>)delegate;

- (void)registerSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate;
- (void)registerWeakSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate;
- (void)removeSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate;

- (void)registerSocketClientReceivingDelegate:(id<VDSocketClientReceivingDelegate>)delegate;
- (void)registerWeakSocketClientReceivingDelegate:(id<VDSocketClientReceivingDelegate>)delegate;
- (void)removeSocketClientReceivingDelegate:(id<VDSocketClientReceivingDelegate>)delegate;

#pragma mark Properties
@property (nonatomic, strong) VDSocketAddress *address;
/**
 *  STRING与byte转换的编码
 *  默认为NoneEncodingType，表示不自动转换byte为string
 */
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, strong) VDSocketPacketHelper *socketPacketHelper;
@property (nonatomic, strong) VDSocketHeartBeatHelper *heartBeatHelper;
@property (nonatomic, strong) VDSocketConfigure *socketConfigure;
@property (nonatomic, assign, readonly) VDSocketClientState state;

#pragma mark Protected Method

#pragma mark Private Method

@end
