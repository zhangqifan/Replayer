//
//  Replayer.h
//
//  Created by zhangqifan on 2017/5/31.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ReplayerPanelProtocol.h"

@class Replayer;
@class ReplayerTask;

/// 视频填充方式
typedef NS_ENUM(NSUInteger, ReplayerVideoGravity) {
    ReplayerVideoGravityResize,
    ReplayerVideoGravityResizeAspect,
    ReplayerVideoGravityResizeAspectFill,
};

/// 播放器当前状态
typedef NS_ENUM(NSUInteger, ReplayerCurrentState) {
    ReplayerCurrentStateFailedToLoad,   // 加载失败
    ReplayerCurrentStateBuffering,      // 正在缓冲
    ReplayerCurrentStatePlaying,        // 正在播放
    ReplayerCurrentStatePaused,         // 暂停
    ReplayerCurrentStateCompleted       // 播放完成
};

/// 播放中的错误处理
typedef NS_ENUM(NSUInteger, ReplayerUnableToResumeReason) {
    ReplayerUnableToResumeReasonSourceGone,     // 播放源失效
    ReplayerUnableToResumeReasonBufferEmpty,    // 缓冲播放完毕并加载超时
    ReplayerUnableToResumeReasonNoNetwork,      // 无网络连接并等待超时
};

@protocol ReplayerDelegate <NSObject>

@required

/**
 承载播放器的视图（通常指当前 viewController）的返回事件
 */
- (void)replayerDidGoBack:(Replayer *)replayer;

@optional

/**
 播放器是否处于正在播放的状态
 
 @param isPlaying 正在播放的状态
 */
- (void)replayerIsPlaying:(BOOL)isPlaying;

/**
 播放器已经获取视频资源并开始播放
 */
- (void)replayerActuallyStreaming;

/**
 进入后台
 
 @param replayer Replayer
 */
- (void)replayerWillBeResignedToBackground:(Replayer *)replayer;

/**
 进入前台
 
 @param replayer Replayer
 */
- (void)replayerDidBecomeActiveToForeground:(Replayer *)replayer;

/**
 播放完毕
 
 @param finishPolicy 播放完毕策略 在播放完毕和显示重新播放视图前插入任意的业务逻辑，完成业务后调用 finishPolicy block 通知播放器显示重新播放按钮
 */
- (void)replayerDidFinishTask:(void (^)(void))finishPolicy;

/**
 播放器重新开始播放
 
 @param replayer Replayer
 */
- (void)replayerDidReplayTask:(Replayer *)replayer;

/**
 网络情况变化的回调
 
 @param networkStatus   @"WWAN" / @"WIFI" / @"NOTREACHABLE" 三种返回
 @param playedTime      已经播放的时间
 */
- (void)replayerDidDetectNetworkStatusChange:(NSString *)networkStatus withPlayedTime:(CGFloat)playedTime;

/**
 继续使用蜂窝数据进行视频播放
 
 @param replayer Replayer
 @discussion 该方法响应的前提是 ReplayerTask 中的 checkCellularEnable 为 YES，默认不响应
 */
- (void)replayerContinuesToPlayDespiteUsingCellularData:(Replayer *)replayer;

/**
 获取视频资源后，返回资源的总时长
 
 @param replayer Replayer
 @param duration 视频总时长
 */
- (void)replayer:(Replayer *)replayer returnVideoFullDuration:(double)duration;

@end

@interface Replayer : UIView <ReplayerPanelProtocol>

@property (nonatomic, weak) id<ReplayerDelegate> delegate;

/*** 视频视图的填充方式 ***/
@property (nonatomic, assign) ReplayerVideoGravity videoGravity;

/*** 播放器当前状态（只读） ***/
@property (nonatomic, assign, readonly) ReplayerCurrentState state;

/*** 允许播放器利用手势进行亮度调节，默认 NO ***/
@property (nonatomic, assign) BOOL enableBrightnessAdjust;

/*** 允许播放器利用手势进行音量调节，默认 NO ***/
@property (nonatomic, assign) BOOL enableVolumeAdjust;

/**
 指定播放器的控制层视图和播放的视频任务
 
 @param panelView 控制层视图，可为 nil
 @param replayerTask 需要播放的任务结构
 @discussion 如使用自定义控制层视图请参照 UIView+ReplayerPanelProtocol 抽象分类，传入 nil 默认使用 ReplayerPanelProtocol 视图，或使用 - replayerUsesDefaultPanelWithTask: 方法
 */
- (void)replayerControlsByPanel:(UIView *)panelView replayerTask:(ReplayerTask *)replayerTask;

/**
 使用默认的播放器控制层视图，指定播放的视频任务
 
 @param replayerTask 需要播放的任务结构
 @discussion 见 - replayerControlsByPanel:replayerTask: 方法
 */
- (void)replayerUsesDefaultPanelWithTask:(ReplayerTask *)replayerTask;

/**
 立即播放
 */
- (void)playInstantlyWhenPrepared;

/**
 通知播放器显示重新播放系列视图
 */
- (void)revealReplayViews;

/**
 暂停
 */
- (void)pause;

/**
 继续播放
 */
- (void)continuePlaying;

/**
 移除正在播放的任务
 */
- (void)removeCurrentTask;

@end
