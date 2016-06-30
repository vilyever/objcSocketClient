//
//  VDSocketAddress.h
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>

#if !VDSocketAddressDefaultConnectionTimeout
#define VDSocketAddressDefaultConnectionTimeout \
(1000 * 15)
#endif

@class VDSocketAddress;


@interface VDSocketAddress : NSObject

#pragma mark Public Method
+ (instancetype)emptyAddress;
+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort;
+ (instancetype)addressWithRemoteIP:(NSString *)remoteIP remotePort:(NSString *)remotePort withConnectionTimeout:(NSInteger)connectionTimeout;
- (void)checkValidation;

#pragma mark Properties
@property (nonatomic, copy) NSString *remoteIP;
@property (nonatomic, copy) NSString *remotePort;
@property (nonatomic, assign) NSInteger connectionTimeout;

@end
