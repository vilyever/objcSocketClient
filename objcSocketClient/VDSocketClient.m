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
static const long VDSocketClientReadBodyWithLengthTag = 2;
static const long VDSocketClientReadTrailerWithLengthTag = 3;
static const long VDSocketClientReadBodyTrailerWithTrailerDataTag = 4;

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

@property (nonatomic, assign, readwrite) VDSocketClientState state;
@property (nonatomic, assign, readwrite) BOOL isDisconnecting;

@property (nonatomic, strong) GCDAsyncSocket *asyncSocket;

@property (nonatomic, strong) VDSocketConfigure *socketConfigure;

@property (nonatomic, strong) NSMutableArray *socketClientDelegates;
@property (nonatomic, strong) NSMutableArray *socketClientSendingDelegates;
@property (nonatomic, strong) NSMutableArray *socketClientRecevingDelegates;

@property (nonatomic, strong) NSMutableArray *sendingPacketQueue;

@property (nonatomic, strong) VDGCDTimer *timer;
@property (nonatomic, assign) NSTimeInterval lastSendHeartBeatMessageTime;
@property (nonatomic, assign) NSTimeInterval lastReceiveMessageTime;

@property (nonatomic, strong) VDSocketPacket *sendingPacket;
@property (nonatomic, strong) dispatch_semaphore_t writeSemaphore;

@property (nonatomic, strong) VDSocketResponsePacket *receivingResponsePacket;
@property (nonatomic, strong) dispatch_semaphore_t readSemaphore;

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
    self.socketConfigure.address = self.address;
    self.socketConfigure.socketPacketHelper = self.socketPacketHelper;
    self.socketConfigure.heartBeatHelper = self.heartBeatHelper;
    
    self.state = VDSocketClientStateConnecting;
    
    NSError *error;
    BOOL requestOK = [self.asyncSocket connectToHost:self.address.remoteIP onPort:[self.address.remotePort integerValue] withTimeout:self.address.connectionTimeout error:&error];
    if (!requestOK || error) {
        NSLog(@"SocketClient request connect failed, error %@", error);
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

- (VDSocketAddress *)connectedAddress {
    return self.socketConfigure.address;
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

- (VDSocketPacket *)sendPacket:(VDSocketPacket *)packet {
    if (![self isConnected]) {
        return nil;
    }
    
    if (!packet) {
        return nil;
    }
    
    VDWeakifySelf;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VDStrongifySelf;
        [self __i__enqueueNewPacket:packet];
    });
    
    return packet;
}

- (void)cancelSend:(VDSocketPacket *)packet {
    VDWeakifySelf;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VDStrongifySelf;
        @synchronized (self.sendingPacketQueue) {
            if ([self.sendingPacketQueue containsObject:packet]) {
                [self.sendingPacketQueue removeObject:packet];
                
                [self __i__onSendPacketCancel:packet];
            }
        }
    });
}

- (VDSocketResponsePacket *)readDataToLength:(NSInteger)length {
    if (![self isConnected]) {
        return nil;
    }
    
    if (self.socketConfigure.socketPacketHelper.readStrategy != VDSocketPacketReadStrategyManually) {
        return nil;
    }
    
    if (self.receivingResponsePacket) {
        return nil;
    }
    
    self.receivingResponsePacket = [VDSocketResponsePacket packet];
    
    VDWeakifySelf;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VDStrongifySelf;
        if (![self isConnected]) {
            return;
        }
        [self __i__onReceiveResponsePacketBegin:self.receivingResponsePacket];
        [self.asyncSocket readDataToLength:length withTimeout:-1 tag:VDSocketClientReadManuallyTag];
        dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
        if (self.receivingResponsePacket) {
            if (self.socketConfigure.encoding != NoneEncodingType) {
                [self.receivingResponsePacket buildStringWithEncoding:self.socketConfigure.encoding];
            }
            [self __i__onReceiveResponsePacketEnd:self.receivingResponsePacket];
            [self __i__onReceiveResponse:self.receivingResponsePacket];
        }
    });
    
    return self.receivingResponsePacket;
}

- (VDSocketResponsePacket *)readDataToData:(NSData *)data {
    if (![self isConnected]) {
        return nil;
    }
    
    if (self.socketConfigure.socketPacketHelper.readStrategy != VDSocketPacketReadStrategyManually) {
        return nil;
    }
    
    if (self.receivingResponsePacket) {
        return nil;
    }
    
    self.receivingResponsePacket = [VDSocketResponsePacket packet];
    
    VDWeakifySelf;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VDStrongifySelf;
        if (![self isConnected]) {
            return;
        }
        [self __i__onReceiveResponsePacketBegin:self.receivingResponsePacket];
        [self.asyncSocket readDataToData:data withTimeout:-1 tag:VDSocketClientReadManuallyTag];
        dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
        if (self.receivingResponsePacket) {
            if (self.socketConfigure.encoding != NoneEncodingType) {
                [self.receivingResponsePacket buildStringWithEncoding:self.socketConfigure.encoding];
            }
            [self __i__onReceiveResponsePacketEnd:self.receivingResponsePacket];
            [self __i__onReceiveResponse:self.receivingResponsePacket];
        }
    });
    
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

- (dispatch_semaphore_t)writeSemaphore {
    if (!_writeSemaphore) {
        _writeSemaphore = dispatch_semaphore_create(0);
    }
    
    return _writeSemaphore;
}

- (dispatch_semaphore_t)readSemaphore {
    if (!_readSemaphore) {
        _readSemaphore = dispatch_semaphore_create(0);
    }
    
    return _readSemaphore;
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
    
    self.state = VDSocketClientStateConnected;

    self.lastSendHeartBeatMessageTime = [NSDate timeIntervalSinceReferenceDate];
    self.lastReceiveMessageTime = [NSDate timeIntervalSinceReferenceDate];
    [self.timer start];
    
    self.sendingPacket = nil;
    self.receivingResponsePacket = nil;
    
    VDWeakifySelf;
    dispatch_async(dispatch_get_main_queue(), ^{
        VDStrongifySelf;
        [self __i__onConnected];
    });
}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err {
    self.isDisconnecting = NO;
    self.state = VDSocketClientStateDisconnected;
    self.socketConfigure = nil;
    
    [self.timer stop];
    
    if (self.sendingPacket) {
        VDSocketPacket *packet = self.sendingPacket;
        self.sendingPacket = nil;
        [self __i__onSendPacketCancel:packet];
    }
    
    VDSocketPacket *packet;
    while ((packet = [self.sendingPacketQueue vd_queuePop])) {
        [self __i__onSendPacketCancel:packet];
    }
    
    if (self.receivingResponsePacket) {
        [self __i__onReceiveResponsePacketCancel:self.receivingResponsePacket];
        self.receivingResponsePacket = nil;
    }
    
    dispatch_semaphore_signal(self.writeSemaphore);
    dispatch_semaphore_signal(self.readSemaphore);
    self.writeSemaphore = nil;
    self.readSemaphore = nil;

    VDWeakifySelf;
    dispatch_async(dispatch_get_main_queue(), ^{
        VDStrongifySelf;
        [self __i__onDisconnected];
    });
}

- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag {
    if (tag == VDSocketClientReadHeaderTag) {
        self.receivingResponsePacket.headerData = data;
    }
    else if (tag == VDSocketClientReadPacketLengthTag) {
        self.receivingResponsePacket.packetLengthData = data;
    }
    else if (tag == VDSocketClientReadBodyWithLengthTag) {
        if (!self.receivingResponsePacket.data) {
            self.receivingResponsePacket.data = [NSMutableData new];
        }
        
        [self.receivingResponsePacket.data appendBytes:[data bytes] length:data.length];
    }
    else if (tag == VDSocketClientReadTrailerWithLengthTag) {
        self.receivingResponsePacket.trailerData = data;
    }
    else if (tag == VDSocketClientReadBodyTrailerWithTrailerDataTag) {
        NSData *trailerData = self.socketConfigure.socketPacketHelper.receiveTrailerData;
        
        self.receivingResponsePacket.data = [NSMutableData dataWithCapacity:data.length - trailerData.length];
        [self.receivingResponsePacket.data appendBytes:[data bytes] length:data.length - trailerData.length];
        self.receivingResponsePacket.trailerData = trailerData;
    }
    else if (tag == VDSocketClientReadManuallyTag) {
        self.receivingResponsePacket.data = [NSMutableData dataWithData:data];
    }
    
    dispatch_semaphore_signal(self.readSemaphore);
}

- (void)socket:(GCDAsyncSocket *)sock didWriteDataWithTag:(long)tag {
    dispatch_semaphore_signal(self.writeSemaphore);
}


#pragma mark Private Method
- (void)__i__enqueueNewPacket:(VDSocketPacket *)packet {
    if (![self isConnected]) {
        return;
    }
    
    @synchronized (self.sendingPacketQueue) {
        [self.sendingPacketQueue vd_queuePush:packet];
    }
    
    [self __i__sendNextPacket];
}

- (void)__i__sendNextPacket {
    if (![self isConnected]) {
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
    
    VDSocketPacket *packet = self.sendingPacket;
    
    if (!self.sendingPacket.data
        && self.sendingPacket.message) {
        if (self.socketConfigure.encoding == NoneEncodingType) {
            NSCAssert(NO, @"we need a string encoding to send String type message");
        }
        else {
            [self.sendingPacket buildDataWithEncoding:self.socketConfigure.encoding];
        }
    }
    
    if (!self.sendingPacket.data) {
        self.sendingPacket = nil;
        [self __i__onSendPacketCancel:packet];
        return;
    }
    
    
    NSData *data = self.sendingPacket.data;
    NSData *headerData = self.socketConfigure.socketPacketHelper.sendHeaderData;
    NSData *trailerData = self.socketConfigure.socketPacketHelper.sendTrailerData;
    NSData *packetLengthData = [self.socketConfigure.socketPacketHelper getSendPacketLengthDataForPacketLength:data.length + trailerData.length];
    
    NSInteger sendedPacketLength = 0;
    
    self.sendingPacket.headerData = headerData;
    self.sendingPacket.trailerData = trailerData;
    self.sendingPacket.packetLengthData = packetLengthData;

    if (headerData.length + packetLengthData.length + data.length + trailerData.length <= 0) {
        self.sendingPacket = nil;
        [self __i__onSendPacketCancel:packet];
        return;
    }
    
    [self __i__onSendPacketBegin:self.sendingPacket];
    [self __i__onSendingPacket:self.sendingPacket withSendedLength:sendedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:data.length trailerLength:trailerData.length];
    
    if (headerData.length > 0) {
        [self.asyncSocket writeData:headerData withTimeout:-1 tag:VDSocketClientWriteHeaderTag];
        dispatch_semaphore_wait(self.writeSemaphore, DISPATCH_TIME_FOREVER);
        if (!self.sendingPacket) {
            return;
        }
        
        sendedPacketLength += headerData.length;
        
        [self __i__onSendingPacket:self.sendingPacket withSendedLength:sendedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:data.length trailerLength:trailerData.length];
    }
    
    if (packetLengthData.length > 0) {
        [self.asyncSocket writeData:packetLengthData withTimeout:-1 tag:VDSocketClientWritePacketLengthTag];
        dispatch_semaphore_wait(self.writeSemaphore, DISPATCH_TIME_FOREVER);
        if (!self.sendingPacket) {
            return;
        }
        
        sendedPacketLength += packetLengthData.length;
        
        [self __i__onSendingPacket:self.sendingPacket withSendedLength:sendedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:data.length trailerLength:trailerData.length];
    }
    
    if (data.length > 0) {
        if (self.socketConfigure.socketPacketHelper.isSendSegmentEnabled) {
            NSInteger segmentLength = self.socketConfigure.socketPacketHelper.sendSegmentLength;
            NSInteger offset = 0;
            while (offset < data.length) {
                NSInteger end = offset + segmentLength;
                end = MIN(end, data.length);
                
                [self.asyncSocket writeData:[data subdataWithRange:NSMakeRange(offset, end - offset)] withTimeout:-1 tag:VDSocketClientWriteBodyTag];
                dispatch_semaphore_wait(self.writeSemaphore, DISPATCH_TIME_FOREVER);
                if (!self.sendingPacket) {
                    return;
                }
                
                sendedPacketLength += end - offset;
                
                [self __i__onSendingPacket:self.sendingPacket withSendedLength:sendedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:data.length trailerLength:trailerData.length];
                
                offset = end;
            }
        }
        else {
            [self.asyncSocket writeData:data withTimeout:-1 tag:VDSocketClientWriteBodyTag];
            dispatch_semaphore_wait(self.writeSemaphore, DISPATCH_TIME_FOREVER);
            if (!self.sendingPacket) {
                return;
            }
            
            sendedPacketLength += data.length;
            
            [self __i__onSendingPacket:self.sendingPacket withSendedLength:sendedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:data.length trailerLength:trailerData.length];
        }
    }
    
    if (trailerData.length > 0) {
        [self.asyncSocket writeData:trailerData withTimeout:-1 tag:VDSocketClientWriteTrailerTag];
        dispatch_semaphore_wait(self.writeSemaphore, DISPATCH_TIME_FOREVER);
        if (!self.sendingPacket) {
            return;
        }
        
        sendedPacketLength += trailerData.length;
        
        [self __i__onSendingPacket:self.sendingPacket withSendedLength:sendedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthData.length dataLength:data.length trailerLength:trailerData.length];
    }
    
    self.sendingPacket = nil;
    [self __i__onSendPacketEnd:packet];
}

- (void)__i__sendHeartBeat {
    if (![self isConnected]) {
        return;
    }
    
    if (!self.socketConfigure.heartBeatHelper.isSendHeartBeatEnabled) {
        return;
    }
    
    VDSocketPacket *packet = [VDSocketPacket heartBeatPacketWithData:[self.socketConfigure.heartBeatHelper getSendData]];
    [self __i__enqueueNewPacket:packet];
}

- (void)__i__readNextResponse {
    if (self.socketConfigure.socketPacketHelper.readStrategy == VDSocketPacketReadStrategyManually) {
        return;
    }
    
    if (![self isConnected]) {
        return;
    }
    
    if (self.receivingResponsePacket) {
        return;
    }
    
    NSData *headerData = self.socketConfigure.socketPacketHelper.receiveHeaderData;
    NSData *trailerData = self.socketConfigure.socketPacketHelper.receiveTrailerData;
    NSInteger packetLengthDataLength = self.socketConfigure.socketPacketHelper.receivePacketLengthDataLength;
    
    NSInteger dataLength = 0;
    NSInteger receiviedPacketLength = 0;
    
    if (!self.receivingResponsePacket) {
        self.receivingResponsePacket = [VDSocketResponsePacket packet];
        
        [self __i__onReceiveResponsePacketBegin:self.receivingResponsePacket];
    }
    
    if (headerData.length > 0) {
        [self.asyncSocket readDataToData:headerData withTimeout:-1 tag:VDSocketClientReadHeaderTag];
        dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
        if (!self.receivingResponsePacket) {
            return;
        }
        
        receiviedPacketLength += headerData.length;
    }
    
    if (self.socketConfigure.socketPacketHelper.readStrategy == VDSocketPacketReadStrategyAutoReadByLength) {
        if (packetLengthDataLength < 0) {
            [self __i__onReceiveResponsePacketCancel:self.receivingResponsePacket];
            self.receivingResponsePacket = nil;
            return;
        }
        else if (packetLengthDataLength == 0) {
            [self __i__onReceiveResponsePacketEnd:self.receivingResponsePacket];
            [self __i__onReceiveResponse:self.receivingResponsePacket];
            self.receivingResponsePacket = nil;
            return;
        }
        
        [self.asyncSocket readDataToLength:packetLengthDataLength withTimeout:-1 tag:VDSocketClientReadPacketLengthTag];
        dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
        if (!self.receivingResponsePacket) {
            return;
        }
        
        receiviedPacketLength += packetLengthDataLength;
        
        NSInteger bodyTrailerLength = [self.socketConfigure.socketPacketHelper getReceivePacketDataLength:self.receivingResponsePacket.packetLengthData];
        
        dataLength = bodyTrailerLength - trailerData.length;

        if (dataLength > 0) {
            if (self.socketConfigure.socketPacketHelper.isReceiveSegmentEnabled) {
                NSInteger segmentLength = self.socketConfigure.socketPacketHelper.receiveSegmentLength;
                NSInteger offset = 0;
                while (offset < dataLength) {
                    NSInteger end = offset + segmentLength;
                    end = MIN(end, dataLength);
                    
                    [self.asyncSocket readDataToLength:(end - offset) withTimeout:-1 tag:VDSocketClientReadBodyWithLengthTag];
                    dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
                    if (!self.receivingResponsePacket) {
                        return;
                    }
                    
                    receiviedPacketLength += end - offset;
                    
                    [self __i__onReceivingResponsePacket:self.receivingResponsePacket withReceivedLength:receiviedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthDataLength dataLength:dataLength trailerLength:trailerData.length];
                    
                    offset = end;
                }

            }
            else {
                [self.asyncSocket readDataToLength:dataLength withTimeout:-1 tag:VDSocketClientReadBodyWithLengthTag];
                dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
                if (!self.receivingResponsePacket) {
                    return;
                }
                
                receiviedPacketLength += self.receivingResponsePacket.data.length;
            }
        }
        else if (dataLength < 0) {
            [self __i__onReceiveResponsePacketCancel:self.receivingResponsePacket];
            self.receivingResponsePacket = nil;
            return;
        }
        
        if (trailerData.length > 0) {
            [self.asyncSocket readDataToLength:trailerData.length withTimeout:-1 tag:VDSocketClientReadTrailerWithLengthTag];
            dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
            if (!self.receivingResponsePacket) {
                return;
            }
            
            receiviedPacketLength += trailerData.length;
            
            [self __i__onReceivingResponsePacket:self.receivingResponsePacket withReceivedLength:receiviedPacketLength headerLength:headerData.length packetLengthDataLength:packetLengthDataLength dataLength:dataLength trailerLength:trailerData.length];
        }
    }
    else if (self.socketConfigure.socketPacketHelper.readStrategy == VDSocketPacketReadStrategyAutoReadToTrailer) {
        if (trailerData.length > 0) {
            [self.asyncSocket readDataToData:trailerData withTimeout:-1 tag:VDSocketClientReadBodyTrailerWithTrailerDataTag];
            dispatch_semaphore_wait(self.readSemaphore, DISPATCH_TIME_FOREVER);
            if (!self.receivingResponsePacket) {
                return;
            }
            
            receiviedPacketLength += self.receivingResponsePacket.data.length;
            receiviedPacketLength += trailerData.length;
        }
        else {
            [self __i__onReceiveResponsePacketCancel:self.receivingResponsePacket];
            self.receivingResponsePacket = nil;
            return;
        }
    }
    
    self.receivingResponsePacket.isHeartBeat = [self.socketConfigure.heartBeatHelper isReceiveHeartBeatPacket:self.receivingResponsePacket];
    
    if (self.socketConfigure.encoding != NoneEncodingType) {
        [self.receivingResponsePacket buildStringWithEncoding:self.socketConfigure.encoding];
    }
    
    [self __i__onReceiveResponsePacketEnd:self.receivingResponsePacket];
    [self __i__onReceiveResponse:self.receivingResponsePacket];
    self.receivingResponsePacket = nil;
    
    [self __i__readNextResponse];
}

- (void)__i__onConnected {
    for (id delegate in [self.socketClientDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClientDidConnected:)]) {
            [delegate socketClientDidConnected:self];
        }
    }
    
    VDWeakifySelf;
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        VDStrongifySelf;
        [self __i__readNextResponse];
    });
}

- (void)__i__onDisconnected {
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
    
    float progress = sendedLength / (float) (headerLength + packetLengthDataLength + dataLength + trailerLength);
    
    for (id delegate in [self.socketClientSendingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:sendingPacket:withSendedLength:progress:)]) {
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
    
    float progress = receivedLength / (float) (headerLength + packetLengthDataLength + dataLength + trailerLength);
    
    for (id delegate in [self.socketClientRecevingDelegates copy]) {
        if ([delegate respondsToSelector:@selector(socketClient:receivingResponsePacket:withReceivedLength:progress:)]) {
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
