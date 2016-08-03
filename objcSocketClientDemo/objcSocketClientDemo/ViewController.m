//
//  ViewController.m
//  objcSocketClientDemo
//
//  Created by FTET on 16/6/29.
//  Copyright © 2016年 vilyever. All rights reserved.
//

#import "ViewController.h"

@import objcSocketClient;
@import objcTemp;

@interface ViewController () <VDSocketClientDelegate, VDSocketClientSendingDelegate>

@property (nonatomic, strong) VDSocketClient *socketClient;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.socketClient = [[VDSocketClient alloc] init];
    self.socketClient.address = [VDSocketAddress addressWithRemoteIP:@"192.168.1.70" remotePort:@"21998"];
    [self.socketClient registerSocketClientDelegate:self];
    [self.socketClient registerSocketClientSendingDelegate:self];
    
    self.socketClient.socketPacketHelper.sendTrailerData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    self.socketClient.socketPacketHelper.receiveTrailerData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    self.socketClient.socketPacketHelper.sendSegmentLength = 1024 * 4;
    
    [self.socketClient.socketPacketHelper setSendPacketLengthDataConvertor:^NSData *(NSInteger packetLength) {
        NSString *ls = [NSString stringWithFormat:@"%@", @(packetLength)];
        NSData *lengthData = [ls dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"length %@", @(lengthData.length));
        return lengthData;
    }];
        
    [self.socketClient connect];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


- (void)onSocketClientConnected:(VDSocketClient *)client {
    NSLog(@"onSocketClientConnected");
//    [self.socketClient sendString:@"from ios"];
    
    UIImage *image = [UIImage imageNamed:@"China"];
    NSData *data = [NSData dataWithData:UIImagePNGRepresentation(image)];
    
    NSLog(@"image length %@", @(data.length));
    
    [self.socketClient sendData:data];
}


- (void)onSocketClientDisconnected:(VDSocketClient *)client {
	NSLog(@"onSocketClientDisconnected");
}

- (void)onSocketClientReceiveHeartBeat:(VDSocketClient *)client {
	NSLog(@"onSocketClientHeartBeat");
}

- (void)onSocketClient:(VDSocketClient *)client receiveResponse:(VDSocketResponsePacket *)packet {
	NSLog(@"response %@", [[NSString alloc] initWithData:packet.data encoding:self.socketClient.encoding]);
}

- (void)onSocketClient:(VDSocketClient *)client sendingBegin:(VDSocketPacket *)packet {
	NSLog(@"sendingBegin %@", @(packet.ID));
}

- (void)onSocketClient:(VDSocketClient *)client sendingEnd:(VDSocketPacket *)packet {
	NSLog(@"sendingEnd %@", @(packet.ID));
}

- (void)onSocketClient:(VDSocketClient *)client sending:(VDSocketPacket *)packet inProgressing:(float)progress {
	NSLog(@"sending %@ %g", @(packet.ID), progress);
}






@end
