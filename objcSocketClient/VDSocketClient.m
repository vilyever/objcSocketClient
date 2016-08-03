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


static const long VDSocketClientReadHeaderTag = 0;
static const long VDSocketClientReadPacketLengthTag = 1;
static const long VDSocketClientReadBodyTrailerTag = 2;

static const long VDSocketClientWriteHeaderTag = 0;
static const long VDSocketClientWritePacketLengthTag = 1;
static const long VDSocketClientWriteBodyTag = 2;
static const long VDSocketClientWriteTrailerTag = 3;


@interface VDSocketClient () <GCDAsyncSocketDelegate>

@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;

@property (nonatomic, assign, readwrite) VDSocketClientState state;

@property (nonatomic, assign) BOOL isDisconnecting;

@property (nonatomic, strong) NSMutableArray *socketClientDelegates;
@property (nonatomic, strong) NSMutableArray *socketClientSendingDelegates;

@property (nonatomic, strong) NSMutableArray *sendingPacketQueue;

@property (nonatomic, strong) VDGCDTimer *timer;
@property (nonatomic, assign) NSTimeInterval lastSendHeartBeatMessageTime;
@property (nonatomic, assign) NSTimeInterval lastReceiveMessageTime;

@property (nonatomic, strong) VDSocketPacket *sendingPacket;
@property (nonatomic, assign) NSInteger sendingPacketLengthDataLength;
@property (nonatomic, assign) NSInteger sendingDataFullLength;
@property (nonatomic, assign) NSInteger sendedDataLength;
@property (nonatomic, strong) VDSocketResponsePacket *receivingResponsePacket;

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
    [self.socketPacketHelper checkValidation];
    
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
    [self sendPacket:packet];
    return packet;
}

- (VDSocketPacket *)sendString:(NSString *)message {
    if (![self isConnected]) {
        return nil;
    }
    
    VDSocketPacket *packet = [VDSocketPacket packetWithString:message];
    [self sendPacket:packet];
    return packet;
}

- (void)sendPacket:(VDSocketPacket *)packet {
    if (!packet) {
        return;
    }
    [self __i__enqueueNewPacket:packet];
}

- (void)cancelSend:(VDSocketPacket *)packet {
    if ([NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            VDStrongifySelf;
            [self cancelSend:packet];
        });
        return;
    }
    
    @synchronized (self.sendingPacketQueue) {
        if ([self.sendingPacketQueue containsObject:packet]) {
            [self.sendingPacketQueue removeObject:packet];
            
            [self __i__onSendPacketCancel:packet];
        }
    }    
}

- (BOOL)isConnected {
    return self.state == VDSocketClientStateConnected;
}

- (BOOL)isConnecting {
	return self.state == VDSocketClientStateConnecting;
}

- (BOOL)isDisconnected {
	return self.state == VDSocketClientStateDisconnected;
}

- (void)registerSocketClientDelegate:(id<VDSocketClientDelegate>)delegate {
    if (![self.socketClientDelegates containsObject:delegate]) {
        [self.socketClientDelegates addObject:delegate];
    }
}

- (void)registerWeakSocketClientDelegate:(id<VDSocketClientDelegate>)delegate {
    if (![self.socketClientDelegates containsObject:delegate]) {
        [self.socketClientDelegates addObject:[VDWeakRef refWithObject:delegate]];
    }
}

- (void)removeSocketClientDelegate:(id<VDSocketClientDelegate>)delegate {
    [self.socketClientDelegates removeObject:delegate];
}

- (void)registerSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate {
    if (![self.socketClientSendingDelegates containsObject:delegate]) {
        [self.socketClientSendingDelegates addObject:delegate];
    }
}

- (void)registerWeakSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate {
    if (![self.socketClientSendingDelegates containsObject:delegate]) {
        [self.socketClientSendingDelegates addObject:[VDWeakRef refWithObject:delegate]];
    }
}

- (void)removeSocketClientSendingDelegate:(id<VDSocketClientSendingDelegate>)delegate {
    [self.socketClientSendingDelegates removeObject:delegate];
}

#pragma mark Properties
- (NSMutableArray *)sendingPacketQueue {
    if (!_sendingPacketQueue) {
        _sendingPacketQueue = [NSMutableArray new];
    }
    
    return _sendingPacketQueue;
}

- (NSMutableArray *)socketClientDelegates {
    if (!_socketClientDelegates) {
        _socketClientDelegates = [NSMutableArray new];
    }
    
    return _socketClientDelegates;
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

- (VDSocketAddress *)address {
    if (!_address) {
        _address = [VDSocketAddress emptyAddress];
    }
    
    return _address;
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

- (void)setState:(VDSocketClientState)state {
    if (_state != state) {
        _state = state;
        
        for (id delegate in [self.socketClientDelegates copy]) {
            if ([delegate respondsToSelector:@selector(socketClient:didChangeState:)]) {
                [delegate socketClient:self didChangeState:_state];
            }
        }
    }
}

- (VDGCDTimer *)timer {
    if (!_timer) {
        VDWeakifySelf;
        _timer = [VDGCDTimer timerWithInterval:1 repeats:YES fireOnMainThread:NO actionBlock:^(VDGCDTimer *timer) {
            VDStrongifySelf;
            [self __i__onTimeTick];
        }];
    }
    
    return _timer;
}

- (VDSocketResponsePacket *)receivingResponsePacket {
    if (!_receivingResponsePacket) {
        _receivingResponsePacket = [VDSocketResponsePacket packet];
    }
    
    return _receivingResponsePacket;
}

#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    
    _asyncSocket = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0)];
    _encoding = NoneEncodingType;
    
    return self;
}

- (void)dealloc {
    
}


#pragma mark Delegates
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(uint16_t)port {
    [sock performBlock:^{
        [sock enableBackgroundingOnSocket];
//        if ([sock enableBackgroundingOnSocket])
//            NSLog(@"Enabled backgrounding on socket");
//        else
//            NSLog(@"Enabling backgrounding failed!");
    }];
    
    self.sendingPacket = nil;
    self.sendingPacketLengthDataLength = 0;
    self.sendedDataLength = 0;
    self.sendingDataFullLength = 0;
    
    self.receivingResponsePacket = nil;
    
    [self __i__onConnected];

    [self __i__readNextResponse];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.sendingPacket = nil;
    self.sendingPacketLengthDataLength = 0;
    self.sendedDataLength = 0;
    self.sendingDataFullLength = 0;
    
    self.receivingResponsePacket = nil;
    
    [self __i__onDisconnected];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == VDSocketClientReadHeaderTag) {
        self.receivingResponsePacket.headerData = self.socketConfigure.socketPacketHelper.receiveHeaderData;
    }
    else if (tag == VDSocketClientReadPacketLengthTag) {
        self.receivingResponsePacket.packetLengthData = data;
    }
    else if (tag == VDSocketClientReadBodyTrailerTag) {
        if (self.socketConfigure.socketPacketHelper.receiveTrailerData) {
            NSInteger trailerLength = self.socketConfigure.socketPacketHelper.receiveTrailerData.length;
            self.receivingResponsePacket.data = [data subdataWithRange:NSMakeRange(0, data.length - trailerLength)];
            self.receivingResponsePacket.trailerData = [data subdataWithRange:NSMakeRange(data.length - trailerLength, trailerLength)];
        }
        else {
            self.receivingResponsePacket.data = data;
            self.receivingResponsePacket.trailerData = nil;
        }
        
        self.receivingResponsePacket.isHeartBeat = [self.socketConfigure.heartBeatHelper isReceiveHeartBeatPacket:self.receivingResponsePacket];
        
        [self __i__onReceiveResponse:self.receivingResponsePacket];
        self.receivingResponsePacket = nil;
    }
    
    [self __i__readNextResponse];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == VDSocketClientWriteHeaderTag) {
        self.sendedDataLength += self.socketConfigure.socketPacketHelper.sendHeaderData.length;
    }
    else if (tag == VDSocketClientWritePacketLengthTag) {
        self.sendedDataLength += self.sendingPacketLengthDataLength;
    }
    else if (tag == VDSocketClientWriteBodyTag) {
        if (self.socketConfigure.socketPacketHelper.sendSegmentEnabled) {
            self.sendedDataLength += self.socketConfigure.socketPacketHelper.sendSegmentLength;
        }
        else {
            self.sendedDataLength += self.sendingPacket.data.length;
        }
        
        self.sendedDataLength = MIN(self.sendedDataLength, self.socketConfigure.socketPacketHelper.sendHeaderData.length + self.sendingPacketLengthDataLength + self.sendingPacket.data.length);
    }
    else if (tag == VDSocketClientWriteTrailerTag) {
        self.sendedDataLength += self.socketConfigure.socketPacketHelper.sendTrailerData.length;
    }


    [self __i__onSendingPacket:self.sendingPacket withSendedLength:self.sendedDataLength headerLength:self.socketConfigure.socketPacketHelper.sendHeaderData.length packetLengthDataLength:self.sendingPacketLengthDataLength dataLength:self.sendingPacket.data.length trailerLength:self.socketConfigure.socketPacketHelper.sendTrailerData.length];
    if (self.sendedDataLength == self.sendingDataFullLength) {
        [self __i__onSendPacketEnd:self.sendingPacket];
    }
    
    self.sendingPacket = nil;
    self.sendingPacketLengthDataLength = 0;
    self.sendedDataLength = 0;
    self.sendingDataFullLength = 0;
    
    [self __i__sendNextPacket];
}


#pragma mark Private Method
- (void)__i__enqueueNewPacket:(VDSocketPacket *)packet {
    if ([NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            VDStrongifySelf;
            [self __i__enqueueNewPacket:packet];
        });
        return;
    }
    
    @synchronized (self.sendingPacketQueue) {
        [self.sendingPacketQueue vd_queuePush:packet];
    }
    
    [self __i__sendNextPacket];
}

- (void)__i__sendNextPacket {
    if ([NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            VDStrongifySelf;
            [self __i__sendNextPacket];
        });
        return;
    }
    
    if (self.sendingPacket) {
        return;
    }
    
    @synchronized (self.sendingPacketQueue) {
        self.sendingPacket = [self.sendingPacketQueue vd_queuePop];
    }
    
    if (!self.sendingPacket) {
        return;
    }
    
    if (!self.sendingPacket.data
        && self.sendingPacket.message) {
        if (self.encoding == NoneEncodingType) {
            NSCAssert(NO, @"we need a string encoding to send String type message");
        }
        else {
            [self.sendingPacket buildDataWithEncoding:self.encoding];
        }
    }
    
    if (!self.sendingPacket.data) {
        [self __i__onSendPacketCancel:self.sendingPacket];
        return;
    }

    NSData *headerData = self.socketConfigure.socketPacketHelper.sendHeaderData;
    NSData *trailerData = self.socketConfigure.socketPacketHelper.sendTrailerData;
    NSData *packetLengthData = [self.socketConfigure.socketPacketHelper getSendPacketLengthDataForPacketLength:self.sendingPacket.data.length + trailerData.length];
    
    self.sendingPacketLengthDataLength = packetLengthData.length;
    self.sendingDataFullLength = headerData.length + packetLengthData.length + self.sendingPacket.data.length + trailerData.length;
    
    [self __i__onSendPacketBegin:self.sendingPacket];
    [self __i__onSendingPacket:self.sendingPacket withSendedLength:0 headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:self.sendingPacket.data.length trailerLength:trailerData.length];
    
    if (headerData) {
        [self.asyncSocket writeData:headerData withTimeout:-1 tag:VDSocketClientWriteHeaderTag];
    }
    
    if (packetLengthData) {
        [self.asyncSocket writeData:packetLengthData withTimeout:-1 tag:VDSocketClientWritePacketLengthTag];
    }
    
    if (self.socketConfigure.socketPacketHelper.sendSegmentEnabled) {
        NSInteger segmentLength = self.socketConfigure.socketPacketHelper.sendSegmentLength;
        NSInteger offset = 0;
        while (offset < self.sendingPacket.data.length) {
            NSInteger end = offset + segmentLength;
            end = MIN(end, self.sendingPacket.data.length);
            [self.asyncSocket writeData:[self.sendingPacket.data subdataWithRange:NSMakeRange(offset, end - offset)] withTimeout:-1 tag:VDSocketClientWriteBodyTag];
            offset = end;
        }
    }
    else {
        [self.asyncSocket writeData:self.sendingPacket.data withTimeout:-1 tag:VDSocketClientWriteBodyTag];
    }
    
    if (trailerData) {
        [self.asyncSocket writeData:trailerData withTimeout:-1 tag:VDSocketClientWriteTrailerTag];
    }
}

- (void)__i__sendHeartBeat {
    if ([NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            VDStrongifySelf;
            [self __i__sendHeartBeat];
        });
        return;
    }
    
    if (![self.socketConfigure.heartBeatHelper sendHeartBeatEnabled]) {
        return;
    }
    
    VDSocketPacket *packet = [VDSocketPacket heartBeatPacketWithData:[self.socketConfigure.heartBeatHelper getSendData]];
    [self __i__enqueueNewPacket:packet];
}

- (void)__i__readNextResponse {
    if ([NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            VDStrongifySelf;
            [self __i__readNextResponse];
        });
        return;
    }
    
    if (![self isConnected]) {
        return;
    }
    
    if (self.socketConfigure.socketPacketHelper.receiveHeaderData
        && !self.receivingResponsePacket.headerData) {
        [self.asyncSocket readDataToData:self.socketConfigure.socketPacketHelper.receiveHeaderData withTimeout:-1 tag:VDSocketClientReadHeaderTag];
    }
    else if ([self.socketConfigure.socketPacketHelper isReadDataWithPacketLength]
             && !self.receivingResponsePacket.packetLengthData) {
        [self.asyncSocket readDataToLength:self.socketConfigure.socketPacketHelper.receivePacketLengthDataLength withTimeout:-1 tag:VDSocketClientReadPacketLengthTag];
    }
    else if (!self.receivingResponsePacket.data) {
        if ([self.socketConfigure.socketPacketHelper isReadDataWithPacketLength]) {
            [self.asyncSocket readDataToLength:[self.socketConfigure.socketPacketHelper getReceivePacketDataLength:self.receivingResponsePacket.packetLengthData] withTimeout:-1 tag:VDSocketClientReadBodyTrailerTag];
        }
        else {
            [self.asyncSocket readDataToData:self.socketConfigure.socketPacketHelper.receiveTrailerData withTimeout:-1 tag:VDSocketClientReadBodyTrailerTag];
        }
    }
}

- (void)__i__onConnected {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onConnected];
        });
        return;
    }
    
    self.state = VDSocketClientStateConnected;

    
    self.lastSendHeartBeatMessageTime = [NSDate timeIntervalSinceReferenceDate];
    self.lastReceiveMessageTime = [NSDate timeIntervalSinceReferenceDate];
    [self.timer start];
    
    for (id delegate in [self.socketClientDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClientDidConnected:)]) {
            [delegate socketClientDidConnected:self];
        }
    }
}

- (void)__i__onDisconnected {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onDisconnected];
        });
        return;
    }
    
    self.isDisconnecting = NO;
    self.state = VDSocketClientStateDisconnected;

    [self.timer stop];
    
    for (id delegate in [self.socketClientDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClientDidDisconnected:)]) {
            [delegate socketClientDidDisconnected:self];
        }
    }
}

- (void)__i__onReceiveResponse:(VDSocketResponsePacket *)packet {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onReceiveResponse:packet];
        });
        return;
    }
    
    self.lastReceiveMessageTime = [NSDate timeIntervalSinceReferenceDate];
    
    for (id delegate in [self.socketClientDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:didReceiveResponse:)]) {
            [delegate socketClient:self didReceiveResponse:packet];
        }
    }
}

- (void)__i__onSendPacketBegin:(VDSocketPacket *)packet {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onSendPacketBegin:packet];
        });
        return;
    }
    
    for (id delegate in [self.socketClientSendingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:didBeginSending:)]) {
            [delegate socketClient:self didBeginSending:packet];
        }
    }
}

- (void)__i__onSendPacketEnd:(VDSocketPacket *)packet {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onSendPacketEnd:packet];
        });
        return;
    }
    
    for (id delegate in [self.socketClientSendingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:didEndSending:)]) {
            [delegate socketClient:self didEndSending:packet];
        }
    }
}

- (void)__i__onSendPacketCancel:(VDSocketPacket *)packet {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onSendPacketCancel:packet];
        });
        return;
    }
    
    for (id delegate in [self.socketClientSendingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:didCancelSending:)]) {
            [delegate socketClient:self didCancelSending:packet];
        }
    }
}

- (void)__i__onSendingPacket:(VDSocketPacket *)packet withSendedLength:(NSInteger)sendedLength headerLength:(NSInteger)headerLength packetLengthDataLength:(NSInteger)packetLengthDataLength dataLength:(NSInteger)dataLength trailerLength:(NSInteger)trailerLength {
    
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onSendingPacket:packet withSendedLength:sendedLength headerLength:headerLength packetLengthDataLength:packetLengthDataLength dataLength:dataLength trailerLength:trailerLength];
        });
        return;
    }
    
    for (id delegate in [self.socketClientSendingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:sendingPacket:withSendedLength:headerLength:packetLengthDataLength:dataLength:trailerLength:)]) {
            [delegate socketClient:self sendingPacket:packet withSendedLength:sendedLength headerLength:headerLength packetLengthDataLength:packetLengthDataLength dataLength:dataLength trailerLength:trailerLength];
        }
    }
}

- (void)__i__onTimeTick {
    if (![self isConnected]) {
        return;
    }
    
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    if (self.socketConfigure.heartBeatHelper.sendHeartBeatEnabled) {
        if (currentTime - self.lastSendHeartBeatMessageTime >= self.socketConfigure.heartBeatHelper.heartBeatInterval) {
            [self __i__sendHeartBeat];
            self.lastSendHeartBeatMessageTime = [NSDate timeIntervalSinceReferenceDate];
        }
    }
    
    if (self.socketConfigure.heartBeatHelper.autoDisconnectOnRemoteNoReplyAliveTimeout) {
        if (currentTime - self.lastReceiveMessageTime >= self.socketConfigure.heartBeatHelper.remoteNoReplyAliveTimeout) {
            [self disconnect];
        }
    }
}

//- (void)__i__doAction:(void(^)(void))block onMainThread:(BOOL)onMainThread {
//    if (!block) {
//        return;
//    }
//    
//    if (onMainThread) {
//        if ([NSThread isMainThread]) {
//            block();
//        }
//        else {
//            dispatch_async(dispatch_get_main_queue(), block);
//        }
//        
//    }
//    
//    if (!onMainThread) {
//        if (![NSThread isMainThread]) {
//            block();
//        }
//        else {
//            dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), block);
//        }
//    }
//    
//}

@end
