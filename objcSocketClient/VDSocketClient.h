//
//  VDSocketClient.h
//  objcTempUtilities
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

@class VDSocketClient;

@protocol VDSocketClientDelegate <NSObject>

@optional
- (void)onSocketClientConnected:(VDSocketClient *)client;
- (void)onSocketClientDisconnected:(VDSocketClient *)client;
- (void)onSocketClient:(VDSocketClient *)client response:(VDSocketResponsePacket *)packet;

@end

@protocol VDSocketClientReceiveDelegate <NSObject>

@optional
- (void)onSocketClient:(VDSocketClient *)client receiveResponse:(VDSocketResponsePacket *)packet;
- (void)onSocketClientReceiveHeartBeat:(VDSocketClient *)client;

@end

@protocol VDSocketClientSendingDelegate <NSObject>

@optional
- (void)onSocketClient:(VDSocketClient *)client sendingBegin:(VDSocketPacket *)packet;
- (void)onSocketClient:(VDSocketClient *)client sendingEnd:(VDSocketPacket *)packet;
//- (void)onSocketClient:(VDSocketClient *)client sendingCancel:(VDSocketPacket *)packet;
- (void)onSocketClient:(VDSocketClient *)client sending:(VDSocketPacket *)packet inProgressing:(float)progress;

@end

@interface VDSocketClient : NSObject

#pragma mark Public Method
- (instancetype)initWithAddress:(VDSocketAddress *)address;

- (void)connect;
- (void)disconnect;
- (VDSocketPacket *)sendString:(NSString *)message;
- (VDSocketPacket *)sendData:(NSData *)data;
//- (void)cancelSend:(VDSocketPacket *)packet;
- (BOOL)isConnected;
- (BOOL)isConnecting;
- (BOOL)isDisconnected;

- (void)registerSocketClientDelegate:(id<VDSocketClientDelegate>)delegate;
- (void)registerWeakSocketClientDelegate:(id<VDSocketClientDelegate>)delegate;
- (void)removeSocketClientDelegate:(id<VDSocketClientDelegate>)delegate;

- (void)registerSocketClientReceiveDelegate:(id<VDSocketClientReceiveDelegate>)delegate;
- (void)registerWeakSocketClientReceiveDelegate:(id<VDSocketClientReceiveDelegate>)delegate;
- (void)removeSocketClientReceiveDelegate:(id<VDSocketClientReceiveDelegate>)delegate;

- (void)registerSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate;
- (void)registerWeakSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate;
- (void)removeSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate;

#pragma mark Properties
@property (nonatomic, strong) VDSocketAddress *address;
/**
 *  STRING与byte转换的编码
 */
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, strong) VDSocketPacketHelper *socketPacketHelper;
@property (nonatomic, strong) VDSocketHeartBeatHelper *heartBeatHelper;
@property (nonatomic, strong) VDSocketConfigure *socketConfigure;
@property (nonatomic, assign, readonly) VDSocketClientState state;

#pragma mark Private Method
- (void)internalSendPacket:(VDSocketPacket *)packet;
- (void)internalSendHeartBeat;
- (void)internalReadNextResponse;
- (void)internalOnConnected;
- (void)internalOnDisconnected;
- (void)internalOnReceiveResponse:(VDSocketResponsePacket *)packet;
- (void)internalOnReceiveHeartBeat;
- (void)internalOnSendPacketBegin:(VDSocketPacket *)packet;
- (void)internalOnSendPacketEnd:(VDSocketPacket *)packet;
- (void)internalOnSendPacketProgressing:(VDSocketPacket *)packet progress:(float)progress;
- (void)internalOnTimeTick;

@end
