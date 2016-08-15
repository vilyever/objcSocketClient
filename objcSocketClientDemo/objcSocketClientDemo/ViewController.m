//
//  ViewController.m
//  objcSocketClientDemo
//
//  Created by FTET on 16/6/29.
//  Copyright © 2016年 vilyever. All rights reserved.
//

#import "ViewController.h"

#import "objcSocketClient.h"

@interface ViewController () <VDSocketClientDelegate, VDSocketClientSendingDelegate, VDSocketClientReceivingDelegate>

@property (nonatomic, strong) VDSocketClient *socketClient;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.socketClient = [[VDSocketClient alloc] init];
    self.socketClient.address = [VDSocketAddress addressWithRemoteIP:@"192.168.1.248" remotePort:@"8566"];
    [self.socketClient registerSocketClientDelegate:self];
    [self.socketClient registerSocketClientSendingDelegate:self];
    [self.socketClient registerSocketClientReceivingDelegate:self];
    
    self.socketClient.socketPacketHelper.sendTrailerData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    self.socketClient.socketPacketHelper.receiveTrailerData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    self.socketClient.socketPacketHelper.readStrategy = VDSocketPacketReadStrategyAutoReadToTrailer;
    
    self.socketClient.encoding = NSUTF8StringEncoding;
        
    [self.socketClient connect];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)socketClientDidConnected:(VDSocketClient *)client {
    NSLog(@"onSocketClientConnected");
//    [self.socketClient sendString:@"from ios"];

    [self.socketClient sendString:@"{\"commandType\":\"0\",\"commandTag\":\"0\",\"flag\":\"\",\"token\":\"\",\"commandValue\":\"设备ID\"}"];
}


- (void)socketClientDidDisconnected:(VDSocketClient *)client {
	NSLog(@"onSocketClientDisconnected");
}

- (void)socketClient:(VDSocketClient *)client didReceiveResponse:(VDSocketResponsePacket *)packet {
	NSLog(@"response %@", packet.message);
    
    dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
        sleep(5);
        [self.socketClient sendString:@"{\"commandType\":\"0\",\"commandTag\":\"0\",\"flag\":\"\",\"token\":\"\",\"commandValue\":\"设备ID\"}"];
    });
}

- (void)socketClient:(VDSocketClient *)client didBeginSending:(VDSocketPacket *)packet {
	NSLog(@"sendingBegin %@", @(packet.ID));
}

- (void)socketClient:(VDSocketClient *)client didEndSending:(VDSocketPacket *)packet {
	NSLog(@"sendingEnd %@", @(packet.ID));
}

- (void)socketClient:(VDSocketClient *)client sendingPacket:(VDSocketPacket *)packet withSendedLength:(NSInteger)sendedLength progress:(float)progress {

	NSLog(@"sending %@ %g", @(packet.ID), progress);
}

- (void)socketClient:(VDSocketClient *)client didBeginReceiving:(VDSocketResponsePacket *)packet {
    NSLog(@"didBeginReceiving");
}

- (void)socketClient:(VDSocketClient *)client didEndReceiving:(VDSocketResponsePacket *)packet {
    NSLog(@"didEndReceiving");
}

- (void)socketClient:(VDSocketClient *)client receivingResponsePacket:(VDSocketResponsePacket *)packet withReceivedLength:(NSInteger)receivedLength progress:(float)progress {

    NSLog(@"receing %g", progress);
}

@end
