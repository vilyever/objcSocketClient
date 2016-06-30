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

@interface ViewController () <VDSocketClientDelegate, VDSocketClientReceiveDelegate, VDSocketClientSendingDelegate>

@property (nonatomic, strong) VDSocketClient *socketClient;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    self.socketClient = [[VDSocketClient alloc] init];
    self.socketClient.address = [VDSocketAddress addressWithRemoteIP:@"192.168.1.70" remotePort:@"21998"];
    [self.socketClient registerSocketClientDelegate:self];
    [self.socketClient registerSocketClientReceiveDelegate:self];
    [self.socketClient registerSocketClientSendingDelegate:self];
    
//    self.socketClient.heartBeatHelper.sendMessage = @"$HB$";
//    self.socketClient.heartBeatHelper.receiveMessage = @"$HB$";
//    self.socketClient.heartBeatHelper.heartBeatInterval = 30;
    self.socketClient.socketPacketHelper.sendTrailerData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    self.socketClient.socketPacketHelper.receiveTrailerData = [NSData dataWithBytes:"\x0D\x0A" length:2];
    self.socketClient.socketPacketHelper.sendSegmentLength = 1024 * 4;
    
    [self.socketClient.socketPacketHelper setSendHeaderDataBlock:^NSData *(NSData *data, BOOL isHeartBeat) {
        NSInteger length = data.length;
        NSString *ls = [NSString stringWithFormat:@"%@", @(length)];
        NSData *headerData = [ls dataUsingEncoding:NSUTF8StringEncoding];
        NSLog(@"header length %@", @(headerData.length));
        return headerData;
    }];
    
    [self.socketClient.socketPacketHelper setReceiveBodyDataLengthBlock:^NSInteger(NSData *headerData) {
        return 100;
    }];
    
    self.socketClient.socketPacketHelper.receiveHeaderDataLength = 8;
        
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
