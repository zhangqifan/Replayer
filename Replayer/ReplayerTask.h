//
//  ReplayerTask.h
//
//  Created by zhangqifan on 2017/5/31.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>

/**
 构建一个视频播放任务
 */

NS_ASSUME_NONNULL_BEGIN

@interface ReplayerTask : NSObject

/*** 视频标题 ***/
@property (nullable, nonatomic, strong) NSString *videoTitle;

/*** 视频 HLS 地址 ***/
@property (nonatomic, strong) NSString *streamingURL;

/*** 视频的唯一标识符，用于存储当前此视频的播放进度 ***/
@property (nullable, nonatomic, strong) NSString *videoIdentifier;

/*** 是否启用存储视频播放进度功能，默认关闭。如果开启，那么必须设置 videoIdentifier 属性，否则该属性无效 ***/
@property (nonatomic, assign, getter=isCachePlayback) BOOL cachePlayback;

/*** 视频封面图（如有提前加载则使用该属性） ***/
@property (nullable, nonatomic, strong) UIImage *coverImage;
/*** 视频封面图源自网络（如两个属性都进行设置，则以加载完毕的图片资源为准，如已经开始播放图片仍未加载，则停止加载） ***/
@property (nullable, nonatomic, strong) NSString *coverImageURL;

/*** 是否启用拦截流量播放功能，默认关闭 ***/
@property (nonatomic, assign, getter=isCheckCellularEnable) BOOL checkCellularEnable;

/*** 标明视频开始播放的时间，以秒为单位，默认为 0 ***/
@property (nonatomic, assign) NSInteger seekTime;

/*** 视频大小，单位为 MB ***/
@property (nonatomic, strong) NSNumber *videoCapacity;

/*** 是否允许状态栏在竖屏模式下也执行隐藏，默认为 YES ***/
@property (nonatomic, assign) BOOL statusBarHiddenInPortrait;

/*!
 清晰度调整数据块 (功能未启用)
 @e.g. @{@"高清720P" : @"https://720p.url", @"标清320P" : @"https://320p.url"}
 */
@property (nonatomic, strong) NSDictionary<NSString *, NSString *> *resolutionDict;

@end

NS_ASSUME_NONNULL_END

