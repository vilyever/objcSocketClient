//
//  VDSocketResponsePacket.m
//  objcTempUtilities
//
//  Created by Deng on 16/6/28.
//  Copyright © Deng. All rights reserved.
//

#import "VDSocketResponsePacket.h"


@interface VDSocketResponsePacket ()

@end


@implementation VDSocketResponsePacket

#pragma mark Constructor
+ (instancetype)packet {
    return [[self alloc] init];
}

#pragma mark Public Method
- (BOOL)isDataEqual:(NSData *)data {
    return [data isEqualToData:self.data];
}

#pragma mark Properties


#pragma mark Overrides
- (instancetype)init {
    self = [super init];
    
    return self;
}

- (void)dealloc {
    
}


#pragma mark Delegates


#pragma mark Private Method

@end
