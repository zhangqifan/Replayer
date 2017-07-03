//
//  ReplayerTask.m
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/5/31.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "ReplayerTask.h"

@implementation ReplayerTask

// 默认的 task 配置
- (instancetype)init {
    if (self = [super init]) {
        _cachePlayback          = NO;
        _checkCellularEnable    = NO;
        _seekTime               = 0;
    }
    return self;
}

@end
