//
//  UIView+ReplayerPanelProtocol.m
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/6/1.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "UIView+ReplayerPanelProtocol.h"
#import <objc/runtime.h>

@implementation UIView (ReplayerPanelProtocol)

/*** runtime associated delegate ***/

- (void)setDelegate:(id<ReplayerPanelProtocol>)delegate {
    objc_setAssociatedObject(self, @selector(delegate), delegate, OBJC_ASSOCIATION_ASSIGN);
}

- (id<ReplayerPanelProtocol>)delegate {
    return objc_getAssociatedObject(self, _cmd);
}

/*** additional doings ***/

- (void)resetReplayerPanel { return; }

/*** 将视频任务给控制板呈现数据，标题/时长 等 ***/
- (void)sendReplayerTask:(ReplayerTask *)task { return; }

/**
 @group methods@ 视频控制板的显示状况
 - replayerPanelShows                   : 显示控制板
 - replayerPanelDisappears              : 隐藏控制板
 - replayerPanelChangesDisplayStatus    : 改变控制板的显示状态
 */
- (void)replayerPanelShows { return; }
- (void)replayerPanelDisappears { return; }
- (void)replayerPanelChangesDisplayStatus { return; }

/*** 取消自动隐藏控制板 ***/
- (void)replayerPanelCancelAutoChangeStatus { return; }

/*** 控制板自动隐藏时间，默认 7 秒钟 ***/
- (NSTimeInterval)replayerPanelKeepToActivateTimeInterval {
    NSTimeInterval timeInterval = 7;
    return timeInterval;
}

/*** 视频播放完毕 ***/
- (void)replayerDidEndStreaming { return; }

/*** 视频因源失效/缓冲无法加载/网络故障造成的视频中途播放问题 ***/
- (void)replayerUnableToResumePlayingWithReason:(ReplayerUnableToResumeReason)cannotResumeReason { return; }

/**
 滑动至当前时长
 
 @param currentSecond 当前时长
 @param totalSeconds 视频总时长
 @param isForward 滑动方向，向后滑动为 YES
 */
- (void)slideToCurrentTime:(CGFloat)currentSecond fullSizeSeconds:(CGFloat)totalSeconds isForward:(BOOL)isForward { return; }

/**
 正常播放状态的时刻/时长/进度条更新
 
 @param currentSecond 当前已播放时长
 @param totalSeconds 视频总时长
 @param playedPercent 进度条已播放比例
 */
- (void)replayerPlaysNormally:(CGFloat)currentSecond fullSizeSeconds:(CGFloat)totalSeconds sliderPlayedPercent:(CGFloat)playedPercent { return; }

/**
 设置缓冲进度
 
 @param bufferProgress 缓冲进度
 */
- (void)replayerSetBufferProgress:(CGFloat)bufferProgress { return; }

/*** 停止滑动并释放手势 ***/
- (void)replayerEndSliding { return; }

/*** 隐藏快进快退视图 ***/
- (void)hideForwardView { return; }

/*** 加载动画 ***/
- (void)loadingAnimation { return; }

/*** 停止加载动画 ***/
- (void)endLoadingAnimation { return; }

/*** 开始播放 ***/
- (void)playWithCurrentTask { return; }

/*** 是否进入了全屏模式 ***/
- (void)replayerDidBecomeFullScreen:(BOOL)isFullScreen { return; }

/*** 使用流量提醒 ***/
- (void)replayerDidUseCellular:(BOOL)useCellular { return; }

/*** 视频任务大小 ***/
- (void)replayerTaskCapacity:(NSNumber *)videoCapacity { return; }

/**
 更改播放按钮状态
 
 @param toPlay 是否调整为播放状态
 */
- (void)replayerTransformsPlayButtonStatus:(BOOL)toPlay { return; }
/**
 更改屏幕锁定按钮状态
 
 @param toLock 是否调整为锁定状态
 */
- (void)replayerTransformsLockButtonStatus:(BOOL)toLock { return; }

@end
