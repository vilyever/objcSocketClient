//
//  VDSocketConfigure.h
//  objcSocketClient
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "VDSocketPacketHelper.h"
#import "VDSocketHeartBeatHelper.h"

@class VDSocketConfigure;


@interface VDSocketConfigure : NSObject

#pragma mark Public Method


#pragma mark Properties
@property (nonatomic, assign) NSStringEncoding encoding;
@property (nonatomic, strong) VDSocketPacketHelper *socketPacketHelper;
@property (nonatomic, strong) VDSocketHeartBeatHelper *heartBeatHelper;

@end
