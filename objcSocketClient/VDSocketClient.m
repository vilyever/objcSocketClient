//
//  VDSocketClient.m
//  objcSocketClient
//
//  Created by Deng on 16/6/27.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketClient.h"
#import <CocoaAsyncSocket/CocoaAsyncSocket.h>
#import <objcTimer/objcTimer.h>
#import <objcBlock/objcBlock.h>
#import <objcWeakRef/objcWeakRef.h>
#import <objcArray/objcArray.h>


static const long VDSocketClientReadHeaderTag = 0;
static const long VDSocketClientReadPacketLengthTag = 1;
static const long VDSocketClientReadBodyTrailerWithLengthTag = 2;
static const long VDSocketClientReadBodyTrailerWithTrailerDataTag = 3;

static const long VDSocketClientReadManuallyTag = 100;


static const long VDSocketClientWriteHeaderTag = 0;
static const long VDSocketClientWritePacketLengthTag = 1;
static const long VDSocketClientWriteBodyTag = 2;
static const long VDSocketClientWriteTrailerTag = 3;


@interface VDSocketClient () <GCDAsyncSocketDelegate>

- (void)__i__enqueueNewPacket:(VDSocketPacket *)packet;
- (void)__i__sendNextPacket;
- (void)__i__sendHeartBeat;
- (void)__i__readNextResponse;

- (void)__i__onConnected;
- (void)__i__onDisconnected;
- (void)__i__onReceiveResponse:(VDSocketResponsePacket *)packet;

- (void)__i__onSendPacketBegin:(VDSocketPacket *)packet;
- (void)__i__onSendPacketEnd:(VDSocketPacket *)packet;
- (void)__i__onSendPacketCancel:(VDSocketPacket *)packet;
- (void)__i__onSendingPacket:(VDSocketPacket *)packet withSendedLength:(NSInteger)sendedLength headerLength:(NSInteger)headerLength packetLengthDataLength:(NSInteger)packetLengthDataLength dataLength:(NSInteger)dataLength trailerLength:(NSInteger)trailerLength;

- (void)__i__onReceiveResponsePacketBegin:(VDSocketResponsePacket *)packet;
- (void)__i__onReceiveResponsePacketEnd:(VDSocketResponsePacket *)packet;
- (void)__i__onReceiveResponsePacketCancel:(VDSocketResponsePacket *)packet;
- (void)__i__onReceivingResponsePacket:(VDSocketResponsePacket *)packet withReceivedLength:(NSInteger)receivedLength headerLength:(NSInteger)headerLength packetLengthDataLength:(NSInteger)packetLengthDataLength dataLength:(NSInteger)dataLength trailerLength:(NSInteger)trailerLength;


- (void)__i__onTimeTick;

@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;

@property (nonatomic, assign, readwrite) VDSocketClientState state;

@property (nonatomic, assign) BOOL isDisconnecting;

@property (nonatomic, strong) NSMutableArray *socketClientDelegates;
@property (nonatomic, strong) NSMutableArray *socketClientSendingDelegates;
@property (nonatomic, strong) NSMutableArray *socketClientRecevingDelegates;

@property (nonatomic, strong) NSMutableArray *sendingPacketQueue;

@property (nonatomic, strong) VDGCDTimer *timer;
@property (nonatomic, assign) NSTimeInterval lastSendHeartBeatMessageTime;
@property (nonatomic, assign) NSTimeInterval lastReceiveMessageTime;

@property (nonatomic, strong) VDSocketPacket *sendingPacket;
@property (nonatomic, assign) NSUInteger sendingHeaderDataLength;
@property (nonatomic, assign) NSUInteger sendingPacketLengthDataLength;
@property (nonatomic, assign) NSUInteger sendingDataLength;
@property (nonatomic, assign) NSUInteger sendingTrailerDataLength;
@property (nonatomic, assign) NSUInteger sendingPacketFullLength;
@property (nonatomic, assign) NSUInteger sendedPacketDataLength;

@property (nonatomic, strong) VDSocketResponsePacket *receivingResponsePacket;
@property (nonatomic, assign) NSUInteger receivingHeaderDataLength;
@property (nonatomic, assign) NSUInteger receivingPacketLengthDataLength;
@property (nonatomic, assign) NSUInteger receivingDataLength;
@property (nonatomic, assign) NSUInteger receivingTrailerDataLength;
@property (nonatomic, assign) NSUInteger receivingResponsePacketFullLength;
@property (nonatomic, assign) NSUInteger receiviedResponsePacketLength;

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

- (BOOL)isConnected {
    return self.state == VDSocketClientStateConnected;
}

- (BOOL)isConnecting {
    return self.state == VDSocketClientStateConnecting;
}

- (BOOL)isDisconnected {
    return self.state == VDSocketClientStateDisconnected;
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

- (VDSocketResponsePacket *)readDataToLength:(NSInteger)length {
    if (![self isConnected]) {
        return nil;
    }
    
    if (self.receivingResponsePacket) {
        return nil;
    }
    
    self.receivingResponsePacket = [VDSocketResponsePacket packet];
    
    [self.asyncSocket readDataToLength:length withTimeout:-1 tag:VDSocketClientReadManuallyTag];
    
    return self.receivingResponsePacket;
}

- (VDSocketResponsePacket *)readDataToData:(NSData *)data {
    if (![self isConnected]) {
        return nil;
    }
    
    if (self.receivingResponsePacket) {
        return nil;
    }
    
    self.receivingResponsePacket = [VDSocketResponsePacket packet];
    
    [self.asyncSocket readDataToData:data withTimeout:-1 tag:VDSocketClientReadManuallyTag];
    
    return self.receivingResponsePacket;
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

- (void)registerSocketClientReceivingDelegate:(id<VDSocketClientReceivingDelegate>)delegate {
    if (![self.socketClientRecevingDelegates containsObject:delegate]) {
        [self.socketClientRecevingDelegates addObject:delegate];
    }
}

- (void)registerWeakSocketClientReceivingDelegate:(id<VDSocketClientReceivingDelegate>)delegate {
    if (![self.socketClientRecevingDelegates containsObject:delegate]) {
        [self.socketClientRecevingDelegates addObject:[VDWeakRef refWithObject:delegate]];
    }
}

- (void)removeSocketClientReceivingDelegate:(id<VDSocketClientReceivingDelegate>)delegate {
    [self.socketClientRecevingDelegates removeObject:delegate];
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

- (NSMutableArray *)socketClientRecevingDelegates {
    if (!_socketClientRecevingDelegates) {
        _socketClientRecevingDelegates = [NSMutableArray new];
    }
    
    return _socketClientRecevingDelegates;
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
        _timer = [VDGCDTimer timerWithInterval:1 repeats:YES fireOnMainThread:NO action:^(VDGCDTimer *timer) {
            VDStrongifySelf;
            [self __i__onTimeTick];
        }];
    }
    
    return _timer;
}

- (void)setSendingPacket:(VDSocketPacket *)sendingPacket {
    if (_sendingPacket != sendingPacket) {
        _sendingPacket = sendingPacket;
        self.sendingHeaderDataLength = 0;
        self.sendingPacketLengthDataLength = 0;
        self.sendingDataLength = 0;
        self.sendingTrailerDataLength = 0;
        self.sendingPacketFullLength = 0;
        self.sendedPacketDataLength = 0;
    }
}

- (void)setReceivingResponsePacket:(VDSocketResponsePacket *)receivingResponsePacket {
    if (_receivingResponsePacket != receivingResponsePacket) {
        _receivingResponsePacket = receivingResponsePacket;
        self.receivingHeaderDataLength = 0;
        self.receivingPacketLengthDataLength = 0;
        self.receivingDataLength = 0;
        self.receivingTrailerDataLength = 0;
        self.receivingResponsePacketFullLength = 0;
        self.receivingDataLength = 0;
    }
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
    self.state = VDSocketClientStateConnected;
    
    [sock performBlock:^{
        [sock enableBackgroundingOnSocket];
//        if ([sock enableBackgroundingOnSocket])
//            NSLog(@"Enabled backgrounding on socket");
//        else
//            NSLog(@"Enabling backgrounding failed!");
    }];
    
    [self __i__onConnected];
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.isDisconnecting = NO;
    self.state = VDSocketClientStateDisconnected;
    
    if (self.sendingPacket) {
        [self __i__onSendPacketCancel:self.sendingPacket];
        self.sendingPacket = nil;
    }
    
    VDSocketPacket *packet;
    while ((packet = [self.sendingPacketQueue vd_queuePop])) {
        [self __i__onSendPacketCancel:packet];
    }
    
    if (self.receivingResponsePacket) {
        [self __i__onReceiveResponsePacketCancel:self.receivingResponsePacket];
        self.receivingResponsePacket = nil;
    }
    
    [self __i__onDisconnected];
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    BOOL isCurrentReadOver = NO;
    if (tag == VDSocketClientReadHeaderTag) {
        self.receivingResponsePacket.headerData = self.socketConfigure.socketPacketHelper.receiveHeaderData;
        self.receiviedResponsePacketLength += self.socketConfigure.socketPacketHelper.receiveHeaderData.length;
    }
    else if (tag == VDSocketClientReadPacketLengthTag) {
        self.receivingResponsePacket.packetLengthData = data;
        
        self.receiviedResponsePacketLength += data.length;
    }
    else if (tag == VDSocketClientReadBodyTrailerWithLengthTag) {
        if (!self.receivingResponsePacket.data) {
            self.receivingResponsePacket.data = [NSMutableData dataWithCapacity:self.receivingDataLength];
        }
        
        NSUInteger appendLength = data.length;
        if (self.receivingResponsePacket.data.length + data.length > self.receivingDataLength) {
            appendLength -= self.receivingTrailerDataLength;
            self.receivingResponsePacket.trailerData = self.socketConfigure.socketPacketHelper.receiveTrailerData;
        }
        
        [self.receivingResponsePacket.data appendBytes:[data bytes] length:appendLength];

        self.receiviedResponsePacketLength += data.length;
        
        [self __i__onReceivingResponsePacket:self.receivingResponsePacket withReceivedLength:self.receiviedResponsePacketLength headerLength:self.socketConfigure.socketPacketHelper.receiveHeaderData.length packetLengthDataLength:self.receivingPacketLengthDataLength dataLength:self.receivingResponsePacket.data.length trailerLength:self.socketConfigure.socketPacketHelper.receiveTrailerData.length];
        
        if (self.receiviedResponsePacketLength == self.receivingResponsePacketFullLength) {
            isCurrentReadOver = YES;
        }
    }
    else if (tag == VDSocketClientReadBodyTrailerWithTrailerDataTag) {
        self.receivingResponsePacket.data = [NSMutableData dataWithCapacity:data.length - self.receivingTrailerDataLength];
        [self.receivingResponsePacket.data appendBytes:[data bytes] length:data.length - self.receivingTrailerDataLength];
        self.receivingResponsePacket.trailerData = self.socketConfigure.socketPacketHelper.receiveTrailerData;
        
        self.receiviedResponsePacketLength += data.length;
        
        [self __i__onReceivingResponsePacket:self.receivingResponsePacket withReceivedLength:self.receiviedResponsePacketLength headerLength:self.receivingHeaderDataLength packetLengthDataLength:0 dataLength:self.receivingResponsePacket.data.length trailerLength:self.receivingTrailerDataLength];
        
        isCurrentReadOver = YES;
    }
    else if (tag == VDSocketClientReadManuallyTag) {
        self.receivingResponsePacket.data = [NSMutableData dataWithData:data];
        
        self.receiviedResponsePacketLength += data.length;
        
        [self __i__onReceivingResponsePacket:self.receivingResponsePacket withReceivedLength:data.length headerLength:0 packetLengthDataLength:0 dataLength:data.length trailerLength:0];
        
        isCurrentReadOver = YES;
    }
    
    if (isCurrentReadOver) {
        self.receivingResponsePacket.isHeartBeat = [self.socketConfigure.heartBeatHelper isReceiveHeartBeatPacket:self.receivingResponsePacket];
        
        if (self.encoding != NoneEncodingType) {
            [self.receivingResponsePacket buildStringWithEncoding:self.encoding];
        }
        
        VDSocketResponsePacket *packet = self.receivingResponsePacket;
        self.receivingResponsePacket = nil;
        
        [self __i__onReceiveResponsePacketEnd:packet];
        [self __i__onReceiveResponse:packet];
    }
    
    [self __i__readNextResponse];
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    if (tag == VDSocketClientWriteHeaderTag) {
        self.sendedPacketDataLength += self.sendingHeaderDataLength;
    }
    else if (tag == VDSocketClientWritePacketLengthTag) {
        self.sendedPacketDataLength += self.sendingPacketLengthDataLength;
    }
    else if (tag == VDSocketClientWriteBodyTag) {
        if (self.socketConfigure.socketPacketHelper.isSendSegmentEnabled) {
            self.sendedPacketDataLength += self.socketConfigure.socketPacketHelper.sendSegmentLength;
        }
        else {
            self.sendedPacketDataLength += self.sendingDataLength;
        }
        
        self.sendedPacketDataLength = MIN(self.sendedPacketDataLength, self.sendingHeaderDataLength + self.sendingPacketLengthDataLength + self.sendingDataLength);
    }
    else if (tag == VDSocketClientWriteTrailerTag) {
        self.sendedPacketDataLength += self.sendingTrailerDataLength;
    }


    [self __i__onSendingPacket:self.sendingPacket withSendedLength:self.sendedPacketDataLength headerLength:self.sendingHeaderDataLength packetLengthDataLength:self.sendingPacketLengthDataLength dataLength:self.sendingDataLength trailerLength:self.sendingTrailerDataLength];
    
    if (self.sendedPacketDataLength == self.sendingPacketFullLength) {
        [self __i__onSendPacketEnd:self.sendingPacket];
        
        self.sendingPacket = nil;
    }
    
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
    
    self.sendingPacket.headerData = headerData;
    self.sendingPacket.trailerData = trailerData;
    self.sendingPacket.packetLengthData = packetLengthData;
    
    self.sendingHeaderDataLength = headerData.length;
    self.sendingPacketLengthDataLength = packetLengthData.length;
    self.sendingDataLength = self.sendingPacket.data.length;
    self.sendingTrailerDataLength = trailerData.length;
    self.sendingPacketFullLength = self.sendingHeaderDataLength + self.sendingPacketLengthDataLength + self.sendingDataLength + self.sendingTrailerDataLength;
    
    [self __i__onSendPacketBegin:self.sendingPacket];
    [self __i__onSendingPacket:self.sendingPacket withSendedLength:0 headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:self.sendingPacket.data.length trailerLength:trailerData.length];
    
    if (headerData) {
        [self.asyncSocket writeData:headerData withTimeout:-1 tag:VDSocketClientWriteHeaderTag];
    }
    
    if (packetLengthData) {
        [self.asyncSocket writeData:packetLengthData withTimeout:-1 tag:VDSocketClientWritePacketLengthTag];
    }
    
    if (self.socketConfigure.socketPacketHelper.isSendSegmentEnabled) {
        NSInteger segmentLength = self.socketConfigure.socketPacketHelper.sendSegmentLength;
        NSInteger offset = 0;
        while (offset < self.sendingDataLength) {
            NSInteger end = offset + segmentLength;
            end = MIN(end, self.sendingDataLength);
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
    
    if (!self.socketConfigure.heartBeatHelper.isSendHeartBeatEnabled) {
        return;
    }
    
    VDSocketPacket *packet = [VDSocketPacket heartBeatPacketWithData:[self.socketConfigure.heartBeatHelper getSendData]];
    [self __i__enqueueNewPacket:packet];
}

- (void)__i__readNextResponse {
    if (!self.socketConfigure.socketPacketHelper.autoReceiveEnabled) {
        return;
    }
    
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
    
    if (self.receivingResponsePacket) {
        return;
    }
    
    if (!self.receivingResponsePacket) {
        self.receivingResponsePacket = [VDSocketResponsePacket packet];

        self.receivingHeaderDataLength = self.socketConfigure.socketPacketHelper.receiveHeaderData.length;
        self.receivingPacketLengthDataLength = self.socketConfigure.socketPacketHelper.receivePacketLengthDataLength;
        self.receivingTrailerDataLength = self.socketConfigure.socketPacketHelper.receiveTrailerData.length;
        
        [self __i__onReceiveResponsePacketBegin:self.receivingResponsePacket];
    }
    
    if (self.socketConfigure.socketPacketHelper.receiveHeaderData
        && !self.receivingResponsePacket.headerData) {
        [self.asyncSocket readDataToData:self.socketConfigure.socketPacketHelper.receiveHeaderData withTimeout:-1 tag:VDSocketClientReadHeaderTag];
    }
    else if ([self.socketConfigure.socketPacketHelper isReadDataWithPacketLength]
             && !self.receivingResponsePacket.packetLengthData) {
        [self.asyncSocket readDataToLength:self.receivingPacketLengthDataLength withTimeout:-1 tag:VDSocketClientReadPacketLengthTag];
    }
    else if (!self.receivingResponsePacket.data) {
        if ([self.socketConfigure.socketPacketHelper isReadDataWithPacketLength]) {
            
            NSInteger bodyTrailerLength = [self.socketConfigure.socketPacketHelper getReceivePacketDataLength:self.receivingResponsePacket.packetLengthData];
            self.receivingDataLength = bodyTrailerLength - self.receivingTrailerDataLength;
            
            self.receivingResponsePacketFullLength = self.receivingHeaderDataLength + self.receivingPacketLengthDataLength + self.receivingDataLength + self.receivingTrailerDataLength;
            
            if (self.socketConfigure.socketPacketHelper.isReceiveSegmentEnabled) {
                NSInteger segmentLength = self.socketConfigure.socketPacketHelper.receiveSegmentLength;
                NSInteger offset = 0;
                while (offset < bodyTrailerLength) {
                    NSInteger end = offset + segmentLength;
                    end = MIN(end, bodyTrailerLength);
                    [self.asyncSocket readDataToLength:(end - offset) withTimeout:-1 tag:VDSocketClientReadBodyTrailerWithLengthTag];
                    offset = end;
                }
            }
            else {
                [self.asyncSocket readDataToLength:bodyTrailerLength withTimeout:-1 tag:VDSocketClientReadBodyTrailerWithLengthTag];
            }
        }
        else {
            [self.asyncSocket readDataToData:self.socketConfigure.socketPacketHelper.receiveTrailerData withTimeout:-1 tag:VDSocketClientReadBodyTrailerWithTrailerDataTag];
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
    
    self.lastSendHeartBeatMessageTime = [NSDate timeIntervalSinceReferenceDate];
    self.lastReceiveMessageTime = [NSDate timeIntervalSinceReferenceDate];
    [self.timer start];
    
    for (id delegate in [self.socketClientDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClientDidConnected:)]) {
            [delegate socketClientDidConnected:self];
        }
    }
    
    self.sendingPacket = nil;
    self.receivingResponsePacket = nil;
    [self __i__readNextResponse];
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
    
    self.sendingPacket = nil;
    self.receivingResponsePacket = nil;

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
        if ([delegate respondsToSelector:@selector(socketClient:sendingPacket:withSendedLength:progress:)]) {
            float progress = sendedLength / (float) (headerLength + packetLengthDataLength + dataLength + trailerLength);
            [delegate socketClient:self sendingPacket:packet withSendedLength:sendedLength progress:progress];
        }
    }
}

- (void)__i__onReceiveResponsePacketBegin:(VDSocketResponsePacket *)packet {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onReceiveResponsePacketBegin:packet];
        });
        return;
    }
    
    for (id delegate in [self.socketClientRecevingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:didBeginReceiving:)]) {
            [delegate socketClient:self didBeginReceiving:packet];
        }
    }
}

- (void)__i__onReceiveResponsePacketEnd:(VDSocketResponsePacket *)packet {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onReceiveResponsePacketEnd:packet];
        });
        return;
    }
    
    for (id delegate in [self.socketClientRecevingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:didEndReceiving:)]) {
            [delegate socketClient:self didEndReceiving:packet];
        }
    }
}

- (void)__i__onReceiveResponsePacketCancel:(VDSocketResponsePacket *)packet {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onReceiveResponsePacketCancel:packet];
        });
        return;
    }
    
    for (id delegate in [self.socketClientRecevingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:didCancelReceiving:)]) {
            [delegate socketClient:self didCancelReceiving:packet];
        }
    }
}

- (void)__i__onReceivingResponsePacket:(VDSocketResponsePacket *)packet withReceivedLength:(NSInteger)receivedLength headerLength:(NSInteger)headerLength packetLengthDataLength:(NSInteger)packetLengthDataLength dataLength:(NSInteger)dataLength trailerLength:(NSInteger)trailerLength {
    if (![NSThread isMainThread]) {
        VDWeakifySelf;
        dispatch_async(dispatch_get_main_queue(), ^{
            VDStrongifySelf;
            [self __i__onReceivingResponsePacket:packet withReceivedLength:receivedLength headerLength:headerLength packetLengthDataLength:packetLengthDataLength dataLength:dataLength trailerLength:trailerLength];
        });
        return;
    }
    
    for (id delegate in [self.socketClientRecevingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:receivingResponsePacket:withReceivedLength:progress:)]) {
            
            float progress = receivedLength / (float) (headerLength + packetLengthDataLength + dataLength + trailerLength);
            [delegate socketClient:self receivingResponsePacket:packet withReceivedLength:receivedLength progress:progress];
        }
    }
}

- (void)__i__onTimeTick {
    if (![self isConnected]) {
        return;
    }
    
    NSTimeInterval currentTime = [NSDate timeIntervalSinceReferenceDate];
    if (self.socketConfigure.heartBeatHelper.isSendHeartBeatEnabled) {
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
