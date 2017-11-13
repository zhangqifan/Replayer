//
//  ReplayerTask.m
//
//  Created by zhangqifan on 2017/5/31.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import "ReplayerTask.h"

@implementation ReplayerTask

// 默认的 task 配置
- (instancetype)init {
    if (self = [super init]) {
        _cachePlayback              = NO;
        _checkCellularEnable        = NO;
        _seekTime                   = 0;
        _statusBarHiddenInPortrait  = YES;
    }
    return self;
}

@end

