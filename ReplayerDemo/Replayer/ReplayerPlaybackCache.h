//
//  ReplayerPlaybackCache.h
//  ReplayerDemo
//
//  Created by qifan.zhang on 2017/6/28.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface ReplayerPlaybackCache : NSObject

/**
 保存指定视频的当前播放进度

 @param moment 当前播放进度
 @param videoIdentifier 视频唯一标识符
 */
+ (void)setDownPlaybackCurrentMoment:(double)moment byVideoIdentifier:(NSString * _Nonnull)videoIdentifier;

/**
 取得指定视频的已播放进度

 @param videoIdentifier 视频唯一标识符
 @return 已播放进度
 */
+ (double)fetchPlaybackMomentByVideoIdentifier:(NSString * _Nonnull)videoIdentifier;

@end
