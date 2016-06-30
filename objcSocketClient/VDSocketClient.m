//
//  VDSocketClient.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/27.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketClient.h"

@import objcTemp;
@import CocoaAsyncSocket;

#import "VDSocketPacketSender.h"

#if !VDSocketClientReadDataTag
#define VDSocketClientReadDataTag \
(0)
#endif

#if !VDSocketClientReadLengthTag
#define VDSocketClientReadLengthTag \
(1)
#endif

#if !VDSocketClientWriteHeartBeatTag
#define VDSocketClientWriteHeartBeatTag \
(-1)
#endif


@interface VDSocketClient () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;

@property (nonatomic, assign, readwrite) VDSocketClientState state;

@property (nonatomic, assign) BOOL isDisconnecting;

@property (nonatomic, strong) NSMutableArray *socketClientDelegates;
@property (nonatomic, strong) NSMutableArray *socketClientSendingDelegates;
@property (nonatomic, strong) NSMutableArray *socketClientReceiveDelegates;

@property (nonatomic, strong) NSMutableDictionary *sendingPacketDictionary;

@property (nonatomic, strong) NSTimer *timer;
@property (nonatomic, assign) NSTimeInterval lastSendHeartBeatMessageTime;
@property (nonatomic, assign) NSTimeInterval lastReceiveMessageTime;

@property (nonatomic, strong) NSData *receivingHeaderData;

@end


@implementation VDSocketClient

#pragma mark Public Method
- (instancetype)initWithAddress:(VDSocketAddress *)address {
    self = [self init];
    _address = address;
    return self;
}

- (void)connect {
    if (![self isDisconnected]) {
        return;
    }
    
    if (!self.address) {
        NSCAssert(NO, @"we need Address to connect.");
    }
    
    [self.address checkValidation];
    
    self.socketConfigure.encoding = self.encoding;
    self.socketConfigure.socketPacketHelper = self.socketPacketHelper;
    self.socketConfigure.heartBeatHelper = self.heartBeatHelper;
    
    self.state = VDSocketClientStateConnecting;
    
    NSError *error;
    BOOL requestOK = [self.asyncSocket connectToHost:self.address.remoteIP onPort:[self.address.remotePort integerValue] withTimeout:self.address.connectionTimeout error:&error];
    if (!requestOK || error) {
        NSLog(@"VDSocketClient request connect failed, error %@", error);
    }
}

- (void)disconnect {
    if ([self isDisconnected] || self.isDisconnecting) {
        return;
    }
    
    self.isDisconnecting = YES;
    
    [self.asyncSocket disconnect];
}

- (VDSocketPacket *)sendData:(NSData *)data {
    if (![self isConnected]) {
        return nil;
    }
    
    VDSocketPacket *packet = [VDSocketPacket packetWithData:data];
    [self internalSendPacket:packet];
    return packet;
}

- (VDSocketPacket *)sendString:(NSString *)message {
    if (![self isConnected]) {
        return nil;
    }
    
    VDSocketPacket *packet = [VDSocketPacket packetWithString:message];
    [self internalSendPacket:packet];
    return packet;
}

//- (void)cancelSend:(VDSocketPacket *)packet {
//    if (![self isConnected]) {
//        return;
//    }
//    
//    
//}

- (BOOL)isConnected {
    return self.state == VDSocketClientStateConnected;
}

- (BOOL)isConnecting {
	return self.state == VDSocketClientStateConnecting;
}

- (BOOL)isDisconnected {
	return self.state == VDSocketClientStateDisconnected;
}

- (instancetype)registerSocketClientDelegate:(id<VDSocketClientDelegate>)delegate {
    if (![self.socketClientDelegates containsObject:delegate]) {
        [self.socketClientDelegates addObject:[VDWeakRef refWithObject:delegate]];
    }
    
    return self;
}

- (instancetype)removeSocketClientDelegate:(id<VDSocketClientDelegate>)delegate {
    [self.socketClientDelegates removeObject:delegate];
    
    return self;
}

- (instancetype)registerSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate {
    if (![self.socketClientSendingDelegates containsObject:delegate]) {
        [self.socketClientSendingDelegates addObject:[VDWeakRef refWithObject:delegate]];
    }
    
    return self;
}

- (instancetype)removeSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate {
    [self.socketClientSendingDelegates removeObject:delegate];
    
    return self;
}

- (instancetype)registerSocketClientReceiveDelegate:(id<VDSocketClientReceiveDelegate>)delegate {
    if (![self.socketClientReceiveDelegates containsObject:delegate]) {
        [self.socketClientReceiveDelegates addObject:[VDWeakRef refWithObject:delegate]];
    }
    
    return self;
}

- (instancetype)removeSocketClientReceiveDelegate:(id<VDSocketClientReceiveDelegate>)delegate {
    [self.socketClientReceiveDelegates removeObject:delegate];
    
    return self;
}




#pragma mark Properties
- (NSMutableDictionary *)sendingPacketDictionary {
    if (!_sendingPacketDictionary) {
        _sendingPacketDictionary = [NSMutableDictionary new];
    }
    
    return _sendingPacketDictionary;
}

- (NSMutableArray *)socketClientDelegates {
    if (!_socketClientDelegates) {
        _socketClientDelegates = [NSMutableArray new];
    }
    
    return _socketClientDelegates;
}

- (NSMutableArray *)socketClientReceiveDelegates {
    if (!_socketClientReceiveDelegates) {
        _socketClientReceiveDelegates = [NSMutableArray new];
    }
    
    return _socketClientReceiveDelegates;
}

- (NSMutableArray *)socketClientSendingDelegates {
    if (!_socketClientSendingDelegates) {
        _socketClientSendingDelegates = [NSMutableArray new];
    }
    
    return _socketClientSendingDelegates;
}

- (VDSocketConfigure *)socketConfigure {
    if (!_socketConfigure) {
        _socketConfigure = [[VDSocketConfigure alloc] init];
    }
    
    return _socketConfigure;
}

- (VDSocketPacketHelper *)socketPacketHelper {
    if (!_socketPacketHelper) {
        _socketPacketHelper = [[VDSocketPacketHelper alloc] init];
    }
    
    return _socketPacketHelper;
}

- (VDSocketHeartBeatHelper *)heartBeatHelper {
    if (!_heartBeatHelper) {
        _heartBeatHelper = [[VDSocketHeartBeatHelper alloc] init];
    }
    
    return _heartBeatHelper;
}

#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    if (self) {
        [self internalInit];
    }
    
    return self;
}

- (void)dealloc {
    
}


#pragma mark Delegates
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [sock performBlock:^{
        if ([sock enableBackgroundingOnSocket])
            NSLog(@"Enabled backgrounding on socket");
        else
            NSLog(@"Enabling backgrounding failed!");
    }];
    
    [self internalOnConnected];
    
    [self internalReadNextResponse];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.receivingHeaderData = nil;
    
    [self internalOnDisconnected];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == VDSocketClientReadLengthTag) {
        self.receivingHeaderData = data;
    }
    else if (tag == VDSocketClientReadDataTag) {
        if (![self.socketConfigure.socketPacketHelper isDataWithHeader]) {
            if (self.socketConfigure.socketPacketHelper.receiveTrailerData) {
                NSInteger trailerLength = self.socketConfigure.socketPacketHelper.receiveTrailerData.length;
                data = [data subdataWithRange:NSMakeRange(0, data.length - trailerLength)];
            }
        }
        
        VDSocketResponsePacket *packet = [VDSocketResponsePacket packetWithHeaderData:self.receivingHeaderData bodyData:data];
        self.receivingHeaderData = nil;
        
        [self internalOnReceiveResponse:packet];
    }
    
    [self internalReadNextResponse];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == VDSocketClientWriteHeartBeatTag) {
        return;
    }
    
    VDSocketPacketSender *sender = [self.sendingPacketDictionary objectForKey:@(tag)];
    float progress = [sender getProgressOnNextSended:self.socketConfigure.socketPacketHelper];
    [self internalOnSendPacketProgressing:sender.packet progress:progress];
    if (progress == 1.0f) {
        [self internalOnSendPacketEnd:sender.packet];
    }
}


#pragma mark Private Method
- (void)internalInit {
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    _encoding = NSUTF8StringEncoding;
}

- (void)internalSendPacket:(VDSocketPacket *)packet {
    [self.sendingPacketDictionary setObject:[VDSocketPacketSender senderWithPacket:packet] forKey:@(packet.ID)];
    VDWeakifySelf;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VDStrongifySelf;
        NSData *data = packet.data;
        if (!data) {
            data = [packet.message dataUsingEncoding:self.encoding];
        }
        
        if (!data) {
            return;
        }
        
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self internalOnSendPacketBegin:packet];
            [self internalOnSendPacketProgressing:packet progress:0.0f];
        });
        
        if ([self.socketConfigure.socketPacketHelper isDataWithHeader]) {
            [self.asyncSocket writeData:[self.socketConfigure.socketPacketHelper getSendHeaderDataWithSendingData:data isHeartBeat:NO] withTimeout:-1 tag:packet.ID];
        }

        
        if ([self.socketConfigure.socketPacketHelper shouldSegmentSend]) {
            NSInteger segmentLength = self.socketConfigure.socketPacketHelper.sendSegmentLength;
            NSInteger offset = 0;
            while (offset < data.length) {
                NSInteger end = offset + segmentLength;
                end = MIN(end, data.length);
                [self.asyncSocket writeData:[data subdataWithRange:NSMakeRange(offset, end - offset)] withTimeout:-1 tag:packet.ID];
                offset = end;
            }
        }
        else {
            [self.asyncSocket writeData:data withTimeout:-1 tag:packet.ID];
        }
        
        if (!self.socketConfigure.socketPacketHelper.sendTrailerData && self.socketConfigure.socketPacketHelper.sendTrailerMessage) {
            self.socketConfigure.socketPacketHelper.sendTrailerData = [self.socketConfigure.socketPacketHelper.sendTrailerMessage dataUsingEncoding:self.encoding];
        }
        
        if (self.socketConfigure.socketPacketHelper.sendTrailerData) {
            [self.asyncSocket writeData:self.socketConfigure.socketPacketHelper.sendTrailerData withTimeout:-1 tag:packet.ID];
        }
    });
}

- (void)internalSendHeartBeat {
    if (![self.socketConfigure.heartBeatHelper shouldSendHeartBeat]) {
        return;
    }
    
    VDWeakifySelf;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VDStrongifySelf;
        NSData *data = self.socketConfigure.heartBeatHelper.sendData;
        if (!data) {
            data = [self.socketConfigure.heartBeatHelper.sendMessage dataUsingEncoding:self.encoding];
        }
        
        if (!data) {
            return;
        }
        
        if ([self.socketConfigure.socketPacketHelper isDataWithHeader]) {
            [self.asyncSocket writeData:[self.socketConfigure.socketPacketHelper getSendHeaderDataWithSendingData:data isHeartBeat:YES] withTimeout:-1 tag:VDSocketClientWriteHeartBeatTag];
        }

        [self.asyncSocket writeData:data withTimeout:-1 tag:VDSocketClientWriteHeartBeatTag];
        
        if (!self.socketConfigure.socketPacketHelper.sendTrailerData && self.socketConfigure.socketPacketHelper.sendTrailerMessage) {
            self.socketConfigure.socketPacketHelper.sendTrailerData = [self.socketConfigure.socketPacketHelper.sendTrailerMessage dataUsingEncoding:self.encoding];
        }
        
        if (self.socketConfigure.socketPacketHelper.sendTrailerData) {
            [self.asyncSocket writeData:self.socketConfigure.socketPacketHelper.sendTrailerData withTimeout:-1 tag:VDSocketClientWriteHeartBeatTag];
        }
    });
}

- (void)internalReadNextResponse {
    if (![self isConnected]) {
        return;
    }
    
    if ([self.socketConfigure.socketPacketHelper isDataWithHeader]) {
        if (self.receivingHeaderData) {
            [self.asyncSocket readDataToLength:[self.socketConfigure.socketPacketHelper getReceiveHeaderDataLength] withTimeout:-1 tag:VDSocketClientReadLengthTag];
        }
        else {
            [self.asyncSocket readDataToLength:[self.socketConfigure.socketPacketHelper getReceiveBodyDataLengthWithHeaderData:self.receivingHeaderData] withTimeout:-1 tag:VDSocketClientReadDataTag];
        }
    }
    else {
        // try to do this async
        if (!self.socketConfigure.socketPacketHelper.receiveTrailerData && self.socketConfigure.socketPacketHelper.receiveTrailerMessage) {
            self.socketConfigure.socketPacketHelper.receiveTrailerData = [self.socketConfigure.socketPacketHelper.receiveTrailerMessage dataUsingEncoding:self.encoding];
        }
        
        [self.asyncSocket readDataToData:self.socketConfigure.socketPacketHelper.receiveTrailerData withTimeout:-1 tag:VDSocketClientReadDataTag];
    }
}

- (void)internalOnConnected {
    self.state = VDSocketClientStateConnected;
    
    if (self.timer) {
        [self.timer invalidate];
    }
    
    self.lastSendHeartBeatMessageTime = [NSDate timeIntervalSinceReferenceDate];
    self.lastReceiveMessageTime = [NSDate timeIntervalSinceReferenceDate];
    self.timer = [NSTimer scheduledTimerWithTimeInterval:1 target:self selector:@selector(internalOnTimeTick) userInfo:nil repeats:YES];
    
    for (VDWeakRef *ref in self.socketClientDelegates) {
        id<VDSocketClientDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClientConnected:)]) {
            [delegate onSocketClientConnected:self];
        }
    }
}

- (void)internalOnDisconnected {
    self.isDisconnecting = NO;
    self.state = VDSocketClientStateDisconnected;

    [self.timer invalidate];
    self.timer = nil;
    
    for (VDWeakRef *ref in self.socketClientDelegates) {
        id<VDSocketClientDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClientDisconnected:)]) {
            [delegate onSocketClientDisconnected:self];
        }
    }
}

- (void)internalOnReceiveResponse:(VDSocketResponsePacket *)packet {
    self.lastReceiveMessageTime = [NSDate timeIntervalSinceReferenceDate];
    
    // try to do this async
    if (!self.socketConfigure.heartBeatHelper.receiveData && self.socketConfigure.heartBeatHelper.receiveMessage) {
        self.socketConfigure.heartBeatHelper.receiveData = [self.socketConfigure.heartBeatHelper.receiveMessage dataUsingEncoding:self.encoding];
    }
    
    if ([packet isMatchData:self.socketConfigure.heartBeatHelper.receiveData]) {
        [self internalOnReceiveHeartBeat];
        return;
    }
    
    for (VDWeakRef *ref in self.socketClientDelegates) {
        id<VDSocketClientDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClient:response:)]) {
            [delegate onSocketClient:self response:packet];
        }
    }
    
    for (VDWeakRef *ref in self.socketClientReceiveDelegates) {
        id<VDSocketClientReceiveDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClient:receiveResponse:)]) {
            [delegate onSocketClient:self receiveResponse:packet];
        }
    }
}

- (void)internalOnReceiveHeartBeat {
    
    for (VDWeakRef *ref in self.socketClientReceiveDelegates) {
        id<VDSocketClientReceiveDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClientReceiveHeartBeat:)]) {
            [delegate onSocketClientReceiveHeartBeat:self];
        }
    }
}

- (void)internalOnSendPacketBegin:(VDSocketPacket *)packet {
    
    for (VDWeakRef *ref in self.socketClientSendingDelegates) {
        id<VDSocketClientSendingDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClient:sendingBegin:)]) {
            [delegate onSocketClient:self sendingBegin:packet];
        }
    }
}

- (void)internalOnSendPacketEnd:(VDSocketPacket *)packet {
    
    for (VDWeakRef *ref in self.socketClientSendingDelegates) {
        id<VDSocketClientSendingDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClient:sendingEnd:)]) {
            [delegate onSocketClient:self sendingEnd:packet];
        }
    }
}

//- (void)internalOnSendPacketCancel:(VDSocketPacket *)packet {
//    
//}

- (void)internalOnSendPacketProgressing:(VDSocketPacket *)packet progress:(float)progress {
    
    for (VDWeakRef *ref in self.socketClientSendingDelegates) {
        id<VDSocketClientSendingDelegate> delegate = ref.object;
        if ([delegate respondsToSelector:@selector(onSocketClient:sending:inProgressing:)]) {
            [delegate onSocketClient:self sending:packet inProgressing:progress];
        }
    }
}

- (void)internalOnTimeTick {
    if (![self isConnected]) {
        return;
    }
    
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    if ([self.socketConfigure.heartBeatHelper shouldSendHeartBeat]) {
        if (currentTime - self.lastSendHeartBeatMessageTime >= self.socketConfigure.heartBeatHelper.heartBeatInterval) {
            [self internalSendHeartBeat];
            self.lastSendHeartBeatMessageTime = [NSDate timeIntervalSinceReferenceDate];
        }
    }
    
    if ([self.socketConfigure.heartBeatHelper shouldAutoDisconnectOnRemoteNoReplyTimeout]) {
        if (currentTime - self.lastReceiveMessageTime >= self.socketConfigure.heartBeatHelper.remoteNoReplyAliveTimeout) {
            [self disconnect];
        }
    }
}

@end
