//
//  UIView+ReplayerPanelProtocol.h
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/6/1.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReplayerPanelProtocol.h"
#import "Replayer.h"

@class ReplayerTask;

//REP_EXPORT NSTimeInterval ReplayerPanelKeepToActivateTimeInterval;

/*!
 @important
 此分类为自定义的控制视频播放的视图提供了一些基础的操作方法，运用此分类并在 UIView 的自定义子类中实现抽象方法就能控制方法所对应的 Replayer 播放器的播放流程。
 如需自定义视频控制板，建议使用该分类。
 */
@interface UIView (ReplayerPanelProtocol)

/*** 扩展代理，交由控制板视图持有 ***/
@property (nonatomic, weak) id<ReplayerPanelProtocol> delegate;

/*** 重置控制板的界面展示 ***/
- (void)resetReplayerPanel;

/*** 将视频任务给控制板呈现数据，标题/时长 等 ***/
- (void)sendReplayerTask:(ReplayerTask *)task;

/**
 @group methods@ 视频控制板的显示状况
 - replayerPanelShows                   : 显示控制板
 - replayerPanelDisappears              : 隐藏控制板
 - replayerPanelChangesDisplayStatus    : 改变控制板的显示状态
 */
- (void)replayerPanelShows;
- (void)replayerPanelDisappears;
- (void)replayerPanelChangesDisplayStatus;

/*** 取消自动隐藏控制板 ***/
- (void)replayerPanelCancelAutoChangeStatus;

/*** 控制板自动隐藏时间，默认 7 秒钟 ***/
- (NSTimeInterval)replayerPanelKeepToActivateTimeInterval;

/*** 视频播放完毕 ***/
- (void)replayerDidEndStreaming;

/*** 视频因源失效/缓冲无法加载/网络故障造成的视频播放问题 ***/
- (void)replayerUnableToResumePlayingWithReason:(ReplayerUnableToResumeReason)cannotResumeReason;

/**
 滑动至当前时长
 
 @param currentSecond 当前时长
 @param totalSeconds 视频总时长
 @param isForward 滑动方向，向后滑动为 YES
 */
- (void)slideToCurrentTime:(CGFloat)currentSecond fullSizeSeconds:(CGFloat)totalSeconds isForward:(BOOL)isForward;

/**
 正常播放状态的时刻/时长/进度条更新
 
 @param currentSecond 当前已播放时长
 @param totalSeconds 视频总时长
 @param playedPercent 进度条已播放比例
 */
- (void)replayerPlaysNormally:(CGFloat)currentSecond fullSizeSeconds:(CGFloat)totalSeconds sliderPlayedPercent:(CGFloat)playedPercent;

/**
 设置缓冲进度

 @param bufferProgress 缓冲进度
 */
- (void)replayerSetBufferProgress:(CGFloat)bufferProgress;

/*** 停止滑动并释放手势 ***/
- (void)replayerEndSliding;

/*** 隐藏快进快退视图 ***/
- (void)hideForwardView;

/*** 加载动画 ***/
- (void)loadingAnimation;

/*** 停止加载动画 ***/
- (void)endLoadingAnimation;

/*** 开始播放 ***/
- (void)playWithCurrentTask;

/*** 是否进入了全屏模式 ***/
- (void)replayerDidBecomeFullScreen:(BOOL)isFullScreen;

/*** 使用流量提醒 ***/
- (void)replayerDidUseCellular:(BOOL)useCellular;

/*** 视频任务大小 ***/
- (void)replayerTaskCapacity:(NSNumber *)videoCapacity;

/**
 更改播放按钮状态
 
 @param toPlay 是否调整为播放状态
 */
- (void)replayerTransformsPlayButtonStatus:(BOOL)toPlay;

/**
 更改屏幕锁定按钮状态
 
 @param toLock 是否调整为锁定状态
 */
- (void)replayerTransformsLockButtonStatus:(BOOL)toLock;

@end

