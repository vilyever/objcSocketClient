//
//  VDSocketAddress.h
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>


@class VDSocketAddress;


@interface VDSocketAddress : NSObject <NSCopying>

#pragma mark Constructor
+ (instancetype)emptyAddress;
+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort;
+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort connectionTimeout:(NSTimeInterval)connectionTimeout;

- (instancetype)initWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort connectionTimeout:(NSTimeInterval)connectionTimeout;

#pragma mark Public Method
- (void)checkValidation;

- (void)setRemotePortWithInteger:(NSInteger)port;
- (NSInteger)getRemotePortIntegerValue;

#pragma mark Properties
@property (nonatomic, copy) NSString *remoteIP;
@property (nonatomic, copy) NSString *remotePort;
@property (nonatomic, assign) NSTimeInterval connectionTimeout;

@end
