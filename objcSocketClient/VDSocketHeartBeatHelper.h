//
//  VDSocketHeartBeatHelper.h
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

#if !VDSocketHeartBeatDefaultInterval
#define VDSocketHeartBeatDefaultInterval \
(1000 * 30)
#endif

#if !VDSocketHeartBeatNoneInterval
#define VDSocketHeartBeatNoneInterval \
(-1)
#endif

#if !VDSocketHeartBeatDefaultRemoteNoReplyTimeout
#define VDSocketHeartBeatDefaultRemoteNoReplyTimeout \
(VDSocketHeartBeatDefaultInterval * 2)
#endif

#if !VDSocketHeartBeatNoneRemoteNoReplyTimeout
#define VDSocketHeartBeatNoneRemoteNoReplyTimeout \
(-1)
#endif

@class VDSocketHeartBeatHelper;


@interface VDSocketHeartBeatHelper : NSObject

#pragma mark Public Method
- (void)disableHeartBeat;
- (void)disableRemoteNoReplyTimeout;
- (BOOL)shouldSendHeartBeat;
- (BOOL)shouldAutoDisconnectOnRemoteNoReplyTimeout;

#pragma mark Properties
@property (nonatomic, strong) NSData *sendData;
@property (nonatomic, copy) NSString *sendMessage;
@property (nonatomic, strong) NSData *receiveData;
@property (nonatomic, copy) NSString *receiveMessage;
@property (nonatomic, assign) NSInteger heartBeatInterval;

/**
 *  若远程端在此时长内都没有发送信息到本地，自动断开连接
 */
@property (nonatomic, assign) NSInteger remoteNoReplyAliveTimeout;

@end
