//
//  Replayer.m
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/5/31.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "Replayer.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
#import "Reachability.h"
#import "ReplayerBrightness.h"
#import "ReplayerComposer.h"

/*! 播放器手势滑动方向 */
typedef NS_ENUM(NSUInteger, SwipeDirection) {
    SwipeDirectionHorizontal,   // 横向
    SwipeDirectionVertical,     // 纵向
};

/*! 播放器播放内容监听属性 */
typedef NSString *ReplayerItemObservingProperty;

static ReplayerItemObservingProperty const ReplayerItemObservingStatus             = @"status";
static ReplayerItemObservingProperty const ReplayerItemObservingLoadedTimeRanges   = @"loadedTimeRanges";
static ReplayerItemObservingProperty const ReplayerItemObservingBufferEmpty        = @"playbackBufferEmpty";
static ReplayerItemObservingProperty const ReplayerItemObservingBufferFull         = @"playbackBufferFull";
static ReplayerItemObservingProperty const ReplayerItemObservingLikelyToKeepUp     = @"playbackLikelyToKeepUp";

/*! 加载超时时间 */
typedef NSInteger ReplayerTaskProperty;
static ReplayerTaskProperty const ReplayerTaskFailToContinuePlayingMaxTimeout = 60;

@interface Replayer () <UIGestureRecognizerDelegate>

/*** AVPlayer核心内容 ***/
@property (nonatomic, strong) AVPlayer *player;
@property (nonatomic, strong) AVPlayerItem *playerItem;
@property (nonatomic, strong) AVPlayerLayer *playerLayer;
@property (nonatomic, strong) id timeObserver;
@property (nonatomic, strong) NSString *p_videoGravity;

/*** 播放器当前状态 ***/
@property (nonatomic, assign, readwrite) ReplayerCurrentState state;

/*** 播放器手势 ***/
@property (nonatomic, assign) SwipeDirection swipeDirection;
@property (nonatomic, strong) UITapGestureRecognizer *tapOnceGesture;
@property (nonatomic, strong) UITapGestureRecognizer *doubleTapGesture;
@property (nonatomic, strong) UIPanGestureRecognizer *panGesture;

/*** 外部参数内部引用 ***/
@property (nonatomic, strong) UIView *playerPanel;
@property (nonatomic, strong) ReplayerTask *playTask;

/*** 播放任务内容 ***/
@property (nonatomic, assign) NSInteger seekTime;
@property (nonatomic, strong) NSString *streamingURL;
@property (nonatomic, assign) BOOL checkCellular;       // 是否需要检测流量播放
@property (nonatomic, assign) BOOL denyCellular;        // 用户是否同意使用流量播放
@property (nonatomic, strong) NSNumber *videoCapacity;

/*** 亮度/音量变化视图 ***/
@property (nonatomic, strong) ReplayerBrightness *brightnessAdjust;
@property (nonatomic, strong) UISlider *volumeAdjust;

/*! 播放器控制的变量 */
/*** 是否正在拖动视频进度（水平滑动手势/拖动进度条） ***/
@property (nonatomic, assign, getter=isDragging) BOOL dragging;
/*** 视频是否暂停 ***/
@property (nonatomic, assign, getter=isPaused) BOOL paused;
/*** 是否点击了暂停按钮 ***/
@property (nonatomic, assign, getter=isUserTriggeredPause) BOOL userTriggeredPause;
/*** 是否全屏 ***/
@property (nonatomic, assign, getter=isFullScreen) BOOL fullScreen;
/*** 滑动滑块记录最新的值 ***/
@property (nonatomic, assign) CGFloat latestSliderRecord;
/*** 滑动屏幕记录当前播放时间 ***/
@property (nonatomic, assign) CGFloat swipeForwardTime;
/*** 是否在调整亮度 ***/
@property (nonatomic, assign, getter=isAdjustBrightness) BOOL adjustBrightness;
/*** 视频是否播放完毕 ***/
@property (nonatomic, assign, getter=isEndStreaming) BOOL endStreaming;
/*** 视频是否存在播放错误 ***/
@property (nonatomic, assign, getter=hasError) BOOL error;
/*** 检测网络状态 ***/
@property (nonatomic) Reachability *networkFlag;
@property (nonatomic, assign) NetworkStatus networkStatus;
/*** 记录真实播放时间 ***/
@property (nonatomic, assign) CGFloat feasibleTime;
/*** 加载时间定时器 ***/
@property (nonatomic, strong) dispatch_source_t loadingTimer;
@property (nonatomic, assign) NSInteger timeout;

@end

@implementation Replayer {
    /// 采用 bitfield（位段）来缓存每一次判断是否响应的代理方法，提高了执行效率
    /// based on : https://stackoverflow.com/questions/626898/how-do-i-create-delegates-in-objective-c/626946#626946
    struct {
        unsigned int replayerContainerShouldBeGoBack        : 1;
        unsigned int replayerDidFinishTask                  : 1;
        unsigned int replayerDidDetectNetworkStatusChange   : 1;
        unsigned int replayerWillResignToBackground         : 1;
        unsigned int replayerDidBecomeActive                : 1;
        unsigned int replayerDidReplayTask                  : 1;
    } delegateRespondsCache;
}

@synthesize delegate;

#pragma mark - life cycle

- (instancetype)init {
    if (self = [super init]) {
        self.enableVolumeAdjust     = NO;
        self.enableBrightnessAdjust = NO;
        self.userTriggeredPause     = NO;
        self.fullScreen             = YES;      /// fullscreen: 以后把默认的去掉
        self.backgroundColor = [UIColor blackColor];
    }
    return self;
}

- (void)dealloc {
    self.playerItem = nil;
    // 移除通知
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 移除设备旋转监听
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
    // 移除时间监听
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver = nil;
    }
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

#pragma mark - 内部方法

/**
 配置播放器，配置完毕进入播放状态
 */
- (void)configureReplayer {
    // 设置 AVPlayer 核心参数
    self.playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:self.streamingURL]];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.videoGravity = self.p_videoGravity;
    
    [self configureVolume];
    
    [self activatePeriodTimeObserver];
    
    self.state = ReplayerCurrentStateBuffering;
    
    [self doPlay];
}

/**
 重置播放器状态
 */
- (void)resetReplayer {
    
    self.playerItem         = nil;
    self.seekTime           = 0;
    self.playTask.seekTime  = 0;
    self.feasibleTime       = 0;
    if (self.timeObserver) {
        [self.player removeTimeObserver:self.timeObserver];
        self.timeObserver   = nil;
    }
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [self.playerLayer removeFromSuperlayer];
    [self.player replaceCurrentItemWithPlayerItem:nil];
    [self removeGestureRecognizer:self.tapOnceGesture];
    [self removeGestureRecognizer:self.doubleTapGesture];
    [self removeGestureRecognizer:self.panGesture];
    self.player             = nil;
    self.tapOnceGesture     = nil;
    self.doubleTapGesture   = nil;
    self.panGesture         = nil;
    self.error              = NO;
}

/** 
 添加播放内容的KVO监听&播放完毕通知
 */
- (void)p_addObserversOnPlayerItem {
    [self.playerItem addObserver:self forKeyPath:ReplayerItemObservingStatus options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:ReplayerItemObservingBufferFull options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:ReplayerItemObservingLoadedTimeRanges options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:ReplayerItemObservingBufferEmpty options:NSKeyValueObservingOptionNew context:nil];
    [self.playerItem addObserver:self forKeyPath:ReplayerItemObservingLikelyToKeepUp options:NSKeyValueObservingOptionNew context:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(taskDidPlayInCompletion:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

/**
 移除播放内容的KVO&播放完毕通知
 */
- (void)p_removeObserversOnEmptyPlayerItem {
    [self.playerItem removeObserver:self forKeyPath:ReplayerItemObservingStatus];
    [self.playerItem removeObserver:self forKeyPath:ReplayerItemObservingBufferFull];
    [self.playerItem removeObserver:self forKeyPath:ReplayerItemObservingLoadedTimeRanges];
    [self.playerItem removeObserver:self forKeyPath:ReplayerItemObservingBufferEmpty];
    [self.playerItem removeObserver:self forKeyPath:ReplayerItemObservingLikelyToKeepUp];
    
    [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:self.playerItem];
}

/**
 添加对设备的通知（转屏/耳机/前后台切换）
 */
- (void)p_addDeviceNotifications {
    // 设备旋转
    [[UIDevice currentDevice] beginGeneratingDeviceOrientationNotifications];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
    
    // 耳机监听
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(earphoneAudioRouteDidChange:) name:AVAudioSessionRouteChangeNotification object:nil];
    
    // 应用即将进入后台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appWillBeResignedToBackground) name:UIApplicationWillResignActiveNotification object:nil];
    
    // 应用回到前台
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(appDidBecomeActiveToForeground) name:UIApplicationDidBecomeActiveNotification object:nil];
}

/*** 添加手势 ***/
- (void)p_addGestures {
    // 单击
    [self addGestureRecognizer:self.tapOnceGesture];
    
    // 双击
    [self addGestureRecognizer:self.doubleTapGesture];
    
    // 延迟响应
    [self.tapOnceGesture setDelaysTouchesBegan:YES];
    [self.doubleTapGesture setDelaysTouchesBegan:YES];
    
    // 后面手势响应失败后响应前者
    [self.tapOnceGesture requireGestureRecognizerToFail:self.doubleTapGesture];
}

/**
 添加时刻监听
 */
- (void)activatePeriodTimeObserver {
    __weak typeof(self) weakSelf = self;
    self.timeObserver = [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(1, 1) queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
        AVPlayerItem *currentItem = weakSelf.player.currentItem;
        NSArray *loadedTimeRanges = currentItem.seekableTimeRanges;
        // 是否存在已经缓冲的内容
        if (loadedTimeRanges.count > 0 && currentItem.duration.timescale != 0) {
            // 当前播放时间
            CGFloat currentPlaying = CMTimeGetSeconds([currentItem currentTime]);
            // 视频总体时长
            CGFloat totalRange = (CGFloat)(currentItem.duration.value / currentItem.duration.timescale);
            // 播放进度比例
            CGFloat playedPercent = currentPlaying / totalRange;
            [weakSelf.playerPanel replayerPlaysNormally:currentPlaying fullSizeSeconds:totalRange sliderPlayedPercent:playedPercent];
            // 更新播放时间点
            weakSelf.feasibleTime = currentPlaying;
        }
    }];
}

/*** 初始化系统音量 ***/
- (void)configureVolume {
    // 根据控件名称字符获取私有音量控件
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    self.volumeAdjust = nil;
    for (UIView *element in volumeView.subviews) {
        if ([element.class.description isEqualToString:@"MPVolumeSlider"]) {
            self.volumeAdjust = (UISlider *)element;
            break;
        }
    }
    
    NSError *setAudioError = nil;
    BOOL success = [[AVAudioSession sharedInstance] setCategory:AVAudioSessionCategoryPlayback error:&setAudioError];
    if (!success) {
        
    }
}

/**
 导向至某个时间点（包括滑块的拖拽/记录上次保存的时间点等）

 @param timestamp 视频某个时间点
 @param completionHandler 完成回调
 */
- (void)seekToTimestamp:(CGFloat)timestamp completionHandler:(void (^)(BOOL))completionHandler {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        [self.playerPanel loadingAnimation];
        [self.playerPanel hideForwardView];
        [self.player pause];
        // 构造一个移动到某一个时间点的结构体
        CMTime cmTimestamp = CMTimeMakeWithSeconds(timestamp, self.player.currentItem.duration.timescale);
        __weak typeof(self) weakSelf = self;
        // 精确定位
        [self.player seekToTime:cmTimestamp toleranceBefore:CMTimeMake(1, self.player.currentItem.duration.timescale) toleranceAfter:CMTimeMake(1, self.player.currentItem.duration.timescale) completionHandler:^(BOOL finished) {
            [weakSelf.playerPanel endLoadingAnimation];
            if (completionHandler) {
                completionHandler(finished);
            }
            if (!self.isPaused) {
                [weakSelf.player play];
            }
            [weakSelf.playerPanel replayerEndSliding];
            weakSelf.dragging = NO;
            
            if ([self bufferedDuration] <= 0.0) {
                weakSelf.state = ReplayerCurrentStateBuffering;
            }
        }];
    }
}

/*** 进入播放状态 ***/
- (void)doPlay {
    // 如果已经播放完毕，此时点击播放按钮则重新加载播放器
    if (self.isEndStreaming) {
        self.endStreaming = NO;
        [self.playerPanel resetReplayerPanel];
        self.playTask = _playTask;
        [self doPlay];
    } else {
        [self.playerPanel replayerTransformsPlayButtonStatus:YES];
        if (self.state == ReplayerCurrentStatePaused) {
            self.state = ReplayerCurrentStatePlaying;
        }
        self.paused = NO;
        [self.player play];
    }
}

/*** 进入暂停状态 ***/
- (void)doPause {
    [self.playerPanel replayerTransformsPlayButtonStatus:NO];
    if (self.state == ReplayerCurrentStatePlaying) {
        self.state = ReplayerCurrentStatePaused;
    }
    self.paused = YES;
    [self.player pause];
}

/*** 进入全屏 ***/
- (void)becomeFullScreen {
    
    if (self.isFullScreen) { return; }
    
//    @discussion 实际上，全屏时添加至window上再恢复原始大小需要多一个参数（播放器添加的父视图）来更新约束
//    [self removeFromSuperview];
//    [[[UIApplication sharedApplication] keyWindow] addSubview:self];
    
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self setNeedsLayout];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.fullScreen = YES;
        [self.playerPanel replayerDidBecomeFullScreen:self.isFullScreen];
    }];
}

/*** 退出全屏 ***/
- (void)becomeDefaultScaleOnScreen {
    
    if (!self.isFullScreen) { return; }
    
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.superview);
        make.left.equalTo(self.superview);
        make.right.equalTo(self.superview);
        make.height.equalTo(self.superview.mas_width).multipliedBy(9.0/16.0);
    }];
    
    [self setNeedsLayout];
    
    [UIView animateWithDuration:0.3 animations:^{
        [self layoutIfNeeded];
    } completion:^(BOOL finished) {
        self.fullScreen = NO;
        [self.playerPanel replayerDidBecomeFullScreen:self.isFullScreen];
    }];
}

/*** 强制旋转屏幕 ***/
- (void)forceToChangeDeviceOrientation:(UIInterfaceOrientation)orientation {
    if ([[UIDevice currentDevice] respondsToSelector:@selector(setOrientation:)]) {
        SEL selector = NSSelectorFromString(@"setOrientation:");
        NSInvocation *invocation = [NSInvocation invocationWithMethodSignature:[UIDevice instanceMethodSignatureForSelector:selector]];
        [invocation setSelector:selector];
        [invocation setTarget:[UIDevice currentDevice]];
        int val = orientation;
        [invocation setArgument:&val atIndex:2];
        [invocation invoke];
    }
}

/*** 获取缓冲进度 ***/
- (NSTimeInterval)availableLoadedTimeRanges {
    NSArray *loadedTimeRanges = [self.player.currentItem loadedTimeRanges];
    CMTimeRange timeRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
    
    double startSeconds     = CMTimeGetSeconds(timeRange.start);
    double durationSeconds  = CMTimeGetSeconds(timeRange.duration);
    
    // 返回缓冲总进度 已播放 + 未播放已缓冲
    return (NSTimeInterval)startSeconds + durationSeconds;
}

/*** 获取未播放的缓冲长度 ***/
- (NSTimeInterval)bufferedDuration {
    NSArray *loadedTimeRanges = [self.player.currentItem loadedTimeRanges];
    CMTimeRange timeRange = [[loadedTimeRanges firstObject] CMTimeRangeValue];
    
    double durationSeconds  = CMTimeGetSeconds(timeRange.duration);
    
    return durationSeconds;
}

/*** 在网络情况差的情况下，多缓冲的操作 ***/
- (void)continueBufferInSeconds {
    self.state = ReplayerCurrentStateBuffering;
    
     __block BOOL buffering = NO;
    if (buffering) { return; }
    buffering = YES;
    
    // 网络状况差的情况下需要暂停播放，不然可能会导致视屏卡住时间在走
    [self doPause];
    
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        if (self.isUserTriggeredPause) {
            buffering = NO;
            return;
        }
        
        [self doPlay];
        buffering = NO;
        
        if (!self.playerItem.isPlaybackLikelyToKeepUp) {
            [self continueBufferInSeconds];
        }
    });
}

/*** 网络监听到变化时更新视图操作 ***/
- (void)updateInterfaceWithReachability:(Reachability *)reachability {
    self.networkStatus = [reachability currentReachabilityStatus];
    NSLog(@"当前网络状态 : %ld",(long)self.networkStatus);
    switch (self.networkStatus) {
        case NotReachable:
            if (!self.denyCellular) {
                if (delegateRespondsCache.replayerDidDetectNetworkStatusChange) {
                    [delegate replayerDidDetectNetworkStatusChange:@"NOTREACHABLE" withPlayedTime:self.feasibleTime];
                }
            }
            break;
        case ReachableViaWiFi:
            if (!self.denyCellular) {
                if (delegateRespondsCache.replayerDidDetectNetworkStatusChange) {
                    [delegate replayerDidDetectNetworkStatusChange:@"WIFI" withPlayedTime:self.feasibleTime];
                }
            }
            self.denyCellular = NO;
            break;
        case ReachableViaWWAN: {
            // 用户未同意使用流量
            if (self.denyCellular) {
                [self.playerPanel replayerDidUseCellular:YES];
                [self.playerPanel replayerTaskCapacity:self.videoCapacity];
            } else {
                if (!self.denyCellular) {
                    if (delegateRespondsCache.replayerDidDetectNetworkStatusChange) {
                        [delegate replayerDidDetectNetworkStatusChange:@"WWAN" withPlayedTime:self.feasibleTime];
                    }
                }
            }
        }
            break;
    }
}

/*** 检测loading是否超时 ***/
- (void)checkLoadingTimeout {
    __weak typeof(self) weakSelf = self;
    self.loadingTimer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0));
    dispatch_source_set_timer(self.loadingTimer, dispatch_walltime(NULL, 0), 1.0*NSEC_PER_SEC, 0.1*NSEC_PER_SEC);
    dispatch_source_set_event_handler(self.loadingTimer, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (weakSelf.timeout >= ReplayerTaskFailToContinuePlayingMaxTimeout) {
                weakSelf.error = YES;
                [weakSelf resetReplayer];
                return;
            }
        });
        
        weakSelf.timeout++;
    });
    
    dispatch_resume(self.loadingTimer);
}

#pragma mark - KVO

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    if (object == self.player.currentItem) {
        // 监听 playerItem 的当前状态
        if ([keyPath isEqualToString:ReplayerItemObservingStatus]) {
            if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
                [self setNeedsLayout];
                [self layoutIfNeeded];
                // 视频资源准备完毕，将播放layer添加至播放器layer
                [self.layer insertSublayer:self.playerLayer atIndex:0];
                // 视频资源准备完毕后再生成平移手势
                [self addGestureRecognizer:self.panGesture];
                [self p_addGestures];
                // 开启自动关闭控制板
                [self.playerPanel replayerPanelShows];
                // 外部的继续时间
                if (self.seekTime) {
                    [self seekToTimestamp:self.seekTime completionHandler:NULL];
                    [self.playerPanel toastFromSeekTime:self.seekTime];
                } else {
                    if (self.feasibleTime) {
                        [self seekToTimestamp:self.feasibleTime completionHandler:NULL];
                        self.networkStatus==ReachableViaWWAN ? : [self.playerPanel toastFromSeekTime:self.feasibleTime];
                    }
                }
                if (!self.playerItem.isPlaybackLikelyToKeepUp) {
                    self.state = ReplayerCurrentStateBuffering;
                } else {
                    self.state = ReplayerCurrentStatePlaying;
                }
            } else if (self.player.currentItem.status == AVPlayerItemStatusFailed) {
                self.state = ReplayerCurrentStateFailedToLoad;
            }
        } else if ([keyPath isEqualToString:ReplayerItemObservingLoadedTimeRanges]) {
            // 缓冲进度
            NSTimeInterval buffered = [self availableLoadedTimeRanges];
            double totalSeconds = CMTimeGetSeconds(self.player.currentItem.duration);
            [self.playerPanel replayerSetBufferProgress:buffered / totalSeconds];
            
        } else if ([keyPath isEqualToString:ReplayerItemObservingLikelyToKeepUp]) {
            if (self.playerItem.isPlaybackLikelyToKeepUp && self.state == ReplayerCurrentStateBuffering) {
                self.state = ReplayerCurrentStatePlaying;
            }
        } else if ([keyPath isEqualToString:ReplayerItemObservingBufferEmpty]) {
            NSLog(@"BUFFER EMPTY.");
            // 缓冲为空的情况下，尽量多缓冲一些时间
            if (self.playerItem.isPlaybackBufferEmpty) {
                self.state = ReplayerCurrentStateBuffering;
                if (self.networkStatus != NotReachable) {
                    [self continueBufferInSeconds];
                }
            }
        } else if ([keyPath isEqualToString:ReplayerItemObservingBufferFull]) {
            // 此参数会缓冲至一定时间时收到事件，并不一定是整个视频完全缓冲完毕
            NSLog(@"缓冲完毕");
        }
    }
}

#pragma mark - actions & selectors

/*! 视频已经播放完毕 */
- (void)taskDidPlayInCompletion:(NSNotification *)noti {
    self.endStreaming = YES;
    self.paused = YES;
    if (delegateRespondsCache.replayerDidFinishTask) {
        BOOL allowToReveal = [self.delegate replayerDidFinishTask];
        if (allowToReveal) {
            [self revealReplayViews];
        } else {
            [self.playerPanel replayerPanelDisappears];
        }
    }
}

/*! 设备旋转监听 */
- (void)deviceOrientationDidChange:(NSNotification *)noti {
    UIDeviceOrientation deviceOrientation = [[UIDevice currentDevice] orientation];
    if (deviceOrientation == UIDeviceOrientationLandscapeLeft || deviceOrientation == UIDeviceOrientationLandscapeRight) {
        [self becomeFullScreen];
        
        [self.brightnessAdjust removeFromSuperview];
        [self addSubview:self.brightnessAdjust];
        [self.brightnessAdjust mas_makeConstraints:^(MASConstraintMaker *make) {
            make.width.height.mas_equalTo(155);
            make.center.mas_equalTo(self);
        }];
    }
    if (deviceOrientation == UIDeviceOrientationPortrait) {
        return;
        /// fullscreen: 现在只做横屏
//        [self becomeDefaultScaleOnScreen];
//        
//        [self.brightnessAdjust removeFromSuperview];
//        [[UIApplication sharedApplication].keyWindow addSubview:self.brightnessAdjust];
//        [self.brightnessAdjust mas_makeConstraints:^(MASConstraintMaker *make) {
//            make.width.height.mas_equalTo(155);
//            make.centerX.equalTo(self.brightnessAdjust.superview);
//            make.centerY.equalTo(self.brightnessAdjust.superview);
//        }];
    }
}

/*! 耳机插拔监听 */
- (void)earphoneAudioRouteDidChange:(NSNotification *)noti {
    NSDictionary *audioInteruptionDict = noti.userInfo;
    NSInteger earphoneRouteChange = [[audioInteruptionDict valueForKey:AVAudioSessionRouteChangeReasonKey] integerValue];
    
    switch (earphoneRouteChange) {
        case AVAudioSessionRouteChangeReasonNewDeviceAvailable:
            
            break;
        case AVAudioSessionRouteChangeReasonOldDeviceUnavailable: {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self doPause];
                [self.playerPanel replayerPanelShows];
            });
        }
            break;
        case AVAudioSessionRouteChangeReasonCategoryChange:
            break;
        default:
            break;
    }
}

/*! 应用即将进入后台 */
- (void)appWillBeResignedToBackground {
    [self doPause];
    self.state = ReplayerCurrentStatePaused;
    // 进入后台处理
    if (delegateRespondsCache.replayerWillResignToBackground) {
        [delegate replayer:self willBeResignedToBackgroundToSavePlayedTime:self.feasibleTime];
    }
}

/*! 应用回到前台 */
- (void)appDidBecomeActiveToForeground {
    if (!self.isUserTriggeredPause) {
        [self.playerPanel replayerPanelShows];
        [self doPlay];
        self.state = ReplayerCurrentStatePlaying;
    }
    if (delegateRespondsCache.replayerDidBecomeActive) {
        [delegate replayerDidBecomeActiveToForeground:self];
    }
}

/*! 网络环境变化 */
- (void)reachabilityDidChange:(NSNotification *)noti {
    Reachability *currentReach = [noti object];
    NSParameterAssert([currentReach isKindOfClass:[Reachability class]]);
    [self updateInterfaceWithReachability:currentReach];
}

#pragma mark - 单击/双击/滑动手势

- (void)tapOnceAction:(UIGestureRecognizer *)gesture {
    [self.playerPanel replayerPanelChangesDisplayStatus];
}

- (void)doubleTapAction:(UIGestureRecognizer *)gesture {
    [self.playerPanel replayerPanelShows];
    if (self.isPaused) {
        self.userTriggeredPause = NO;
        [self doPlay];
    } else {
        self.userTriggeredPause = YES;
        [self doPause];
    }
}

- (void)panOnPlayer:(UIPanGestureRecognizer *)gesture {
    
    CGPoint locationPoint = [gesture locationInView:self];
    
    // 判断滑动方向
    CGPoint velocityPoint = [gesture velocityInView:self];
    
    switch (gesture.state) {
        case UIGestureRecognizerStateBegan: {
            // 绝对值
            CGFloat x = fabs(velocityPoint.x);
            CGFloat y = fabs(velocityPoint.y);
            if (x > y) {
                self.swipeDirection = SwipeDirectionHorizontal;
                self.swipeForwardTime = self.player.currentTime.value / self.player.currentTime.timescale;
            } else if (x < y) {
                self.swipeDirection = SwipeDirectionVertical;
                if (locationPoint.x < self.bounds.size.width/2) {
                    self.adjustBrightness = YES;
                } else {
                    self.adjustBrightness = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: {
            if (self.swipeDirection == SwipeDirectionHorizontal) {
                [self panInHorizontal:velocityPoint.x];
            } else if (self.swipeDirection == SwipeDirectionVertical) {
                [self panInVertical:velocityPoint.y];
            }
            break;
        }
        case UIGestureRecognizerStateEnded: {
            if (self.swipeDirection == SwipeDirectionHorizontal) {
                self.dragging = NO;
                [self seekToTimestamp:self.swipeForwardTime completionHandler:NULL];
                self.swipeForwardTime = 0;
            } else if (self.swipeDirection == SwipeDirectionVertical) {
                self.adjustBrightness = YES;
            }
            break;
        }
        default:
            break;
    }
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event {
    if (!self.denyCellular && !self.isEndStreaming) {
        // 单击/双击的响应以及取消
        UITouch *touch = [touches anyObject];
        if (touch.tapCount == 1) {
            [self performSelector:@selector(tapOnceAction:) withObject:nil];
        } else if (touch.tapCount == 2) {
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(tapOnceAction:) object:nil];
            [self doubleTapAction:touch.gestureRecognizers.lastObject];
        }
    }
}

/*** 垂直方向的滑动 ***/
- (void)panInVertical:(CGFloat)panValue {
    if (self.enableBrightnessAdjust && self.isAdjustBrightness) {
        [UIScreen mainScreen].brightness -= panValue / 10000;
    }
    if (self.enableVolumeAdjust && !self.isAdjustBrightness) {
        self.volumeAdjust.value -= panValue / 10000;
    }
}

/*** 水平方向的滑动 ***/
- (void)panInHorizontal:(CGFloat)panValue {
    self.swipeForwardTime += panValue / 200;
    
    // 获取视频总体时间，使得水平滑动的极值不会越过视频长度
    CGFloat duration = (CGFloat)self.player.currentItem.duration.value / self.player.currentItem.duration.timescale;
    
    if (self.swipeForwardTime > duration) {
        self.swipeForwardTime = duration;
    } else if (self.swipeForwardTime < 0) {
        self.swipeForwardTime = 0;
    }
    
    BOOL isForward = NO;
    if (panValue > 0) {
        isForward = YES;
    } else if (panValue < 0) {
        isForward = NO;
    } else if (panValue == 0) {
        return;
    }
    
    self.dragging = YES;
    [self.playerPanel slideToCurrentTime:self.swipeForwardTime fullSizeSeconds:duration isForward:isForward];
}

#pragma mark - UIGestureRecognizeDelegate

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    if ([touch.view isKindOfClass:[UISlider class]]) {
        return NO;
    }
    return YES;
}

#pragma mark - 公共方法

- (void)replayerUsesDefaultPanelWithTask:(ReplayerTask *)replayerTask {
    [self replayerControlsByPanel:nil replayerTask:replayerTask];
}

- (void)replayerControlsByPanel:(UIView *)panelView replayerTask:(ReplayerTask *)replayerTask {
    if (!panelView) {
        ReplayerPanel *panel = [[ReplayerPanel alloc] init];
        self.playerPanel = panel;
    } else {
        self.playerPanel = panelView;
    }
    self.playTask = replayerTask;
}

/*! 资源准备完毕后，设置播放器参数并播放 */
- (void)playInstantlyWhenPrepared {
    // 是预先加载流量监控视图还是直接播放
    if (self.checkCellular && self.networkStatus == ReachableViaWWAN) {
        return;
    }
    [self configureReplayer];
}

/**
 通知播放器显示重新播放系列视图
 */
- (void)revealReplayViews {
    self.state = ReplayerCurrentStateCompleted;
}

/**
 暂停
 */
- (void)pause {
    [self doPause];
}

/**
 继续播放
 */
- (void)continuePlaying {
    if (self.player.currentItem == nil) {
        [self configureReplayer];
    }
    [self doPlay];
}

/**
 移除播放的任务
 */
- (void)removeCurrentTask {
    [self resetReplayer];
}

#pragma mark - ReplayerPanelProtocol

/*** 视频播放 或 暂停 ***/
- (void)replayerPanel:(UIView *)replayerPanel doPlayAction:(id)sender {
    self.paused = !self.paused;
    self.userTriggeredPause = self.isPaused;
    if (self.isPaused) {
        [self doPause];
        if (self.state == ReplayerCurrentStatePlaying) {
            self.state = ReplayerCurrentStatePaused;
        }
    } else {
        // 播放完毕后走重置播放器流程
        if (self.isEndStreaming) {
            [self resetReplayer];
            [self configureReplayer];
            if (delegateRespondsCache.replayerDidReplayTask) {
                [delegate replayerDidReplayTask:self];
            }
        } else if (self.error) {
            [self replayerPanel:self.playerPanel failToLoadOrBuffer:nil];
        } else {
            [self doPlay];
            if (self.state == ReplayerCurrentStatePaused) {
                self.state = ReplayerCurrentStatePlaying;
            }
        }
    }
}

/*** 视频按钮触发全屏 ***/
- (void)replayerPanel:(UIView *)replayerPanel forceToFullScreenAction:(id)sender {
    if ([sender isKindOfClass:[UIButton class]]) {
        UIButton *fullScreenButton = (UIButton *)sender;
        
        if (fullScreenButton.isSelected) {
            [self forceToChangeDeviceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else {
            [self forceToChangeDeviceOrientation:UIInterfaceOrientationPortrait];
        }
        
        !fullScreenButton.isSelected ? [self becomeFullScreen] : [self becomeDefaultScaleOnScreen];
    }
}

/*** 返回按钮触发事件 ***/
- (void)replayerPanel:(UIView *)replayerPanel goBackAction:(id)sender {
    [self doPause];
    if (delegateRespondsCache.replayerContainerShouldBeGoBack) {
        // 回退后停止状态栏的变化
        [self.playerPanel replayerPanelCancelAutoChangeStatus];
        [self.delegate replayer:self goBackWithPlayedTime:self.feasibleTime];
    }
    //// fullscreen: 可调整全屏时启用，现在默认全屏直接 dismiss
//    if (self.isFullScreen) {
//        [self forceToChangeDeviceOrientation:UIInterfaceOrientationPortrait];
//        [self becomeDefaultScaleOnScreen];
//    } else {
//        [self doPause];
//        if (delegateRespondsCache.replayerContainerShouldBeGoBack) {
//            [self.delegate replayerContainerShouldBeGoBack];
//        }
//    }
}

/*** 重播事件 ***/
- (void)replayerPanel:(UIView *)replayerPanel replayAction:(id)sender {
    if (self.isEndStreaming) {
        [self resetReplayer];
        [self configureReplayer];
    }
    if (delegateRespondsCache.replayerDidReplayTask) {
        [delegate replayerDidReplayTask:self];
    }
}

/*** 锁定屏幕操作 ***/
- (void)replayerPanel:(UIView *)replayerPanel forceToLockAction:(id)sender {
    
}

/*** 进度条点击前进 或 后退 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarTapAction:(CGFloat)tapLocation {
    if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
        // 获取视频总长
        CGFloat totalSeconds = (CGFloat)(self.playerItem.duration.value / self.playerItem.duration.timescale);
        // 将点击的位置比例转换成视频对应的时间点
        CGFloat tappedSecond = floorf(totalSeconds * tapLocation);
        [self.playerPanel replayerTransformsPlayButtonStatus:YES];
        [self seekToTimestamp:tappedSecond completionHandler:NULL];
    }
}

/*** 进度条拖动事件 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarValueChanged:(id)sender {
    if ([sender isKindOfClass:[UISlider class]]) {
        UISlider *tracker = (UISlider *)sender;
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            self.dragging = YES;
            // 比较是否是快进还是快退
            BOOL isForward = NO;
            CGFloat compared = tracker.value - self.latestSliderRecord;
            if (compared > 0) {
                isForward = YES;
            } else if (compared < 0) {
                isForward = NO;
            } else if (compared == 0) {
                return;
            }
            self.latestSliderRecord = tracker.value;
            
            CGFloat totalSeconds = (CGFloat)self.player.currentItem.duration.value / self.player.currentItem.duration.timescale;
            
            CGFloat currrentTime = floorf(totalSeconds * tracker.value);
            
            // 显示拖动进度视图
            [replayerPanel slideToCurrentTime:currrentTime fullSizeSeconds:totalSeconds isForward:isForward];
            
            if (totalSeconds <= 0) {
                tracker.value = 0;
            }
            
        } else {
            tracker.value = 0;
        }
    }
}

/*** 进度条触摸结束 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarTouchEnded:(id)sender {
    if ([sender isKindOfClass:[UISlider class]]) {
        UISlider *tracker = (UISlider *)sender;
        if (self.player.currentItem.status == AVPlayerItemStatusReadyToPlay) {
            self.dragging = NO;
            CGFloat totalSeconds = (CGFloat)self.player.currentItem.duration.value / self.player.currentItem.duration.timescale;
            CGFloat currentTime = floorf(totalSeconds * tracker.value);
            [self seekToTimestamp:currentTime completionHandler:NULL];
        }
    }
}

/*** 使用流量播放 ***/
- (void)replayerPanelPassToUseCellular:(UIView *)replayerPanel {
    self.denyCellular = NO;
    [self configureReplayer];
}

/*** 加载或缓冲失败 ***/
- (void)replayerPanel:(UIView *)replayerPanel failToLoadOrBuffer:(id)sender {
    // 重置播放器 & 重置播放器样式 & 重新加载任务 & 设置播放器尝试播放
    [self resetReplayer];
    [self.playerPanel resetReplayerPanel];
    self.playTask = _playTask;
    [self configureReplayer];
}

#pragma mark - getter

- (NSString *)p_videoGravity {
    if (!_p_videoGravity) {
        _p_videoGravity = AVLayerVideoGravityResizeAspect;
    }
    return _p_videoGravity;
}

- (UIPanGestureRecognizer *)panGesture {
    if (!_panGesture) {
        _panGesture = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panOnPlayer:)];
        _panGesture.delegate = self;
        [_panGesture setMaximumNumberOfTouches:1];
        [_panGesture setDelaysTouchesBegan:YES];
        [_panGesture setDelaysTouchesEnded:YES];
        [_panGesture setCancelsTouchesInView:YES];
    }
    return _panGesture;
}

- (UITapGestureRecognizer *)tapOnceGesture {
    if (!_tapOnceGesture) {
        _tapOnceGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnceAction:)];
        _tapOnceGesture.delegate = self;
        _tapOnceGesture.numberOfTouchesRequired = 1;
        _tapOnceGesture.numberOfTapsRequired = 1;
    }
    return _tapOnceGesture;
}

- (UITapGestureRecognizer *)doubleTapGesture {
    if (!_doubleTapGesture) {
        _doubleTapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTapAction:)];
        _doubleTapGesture.delegate = self;
        _doubleTapGesture.numberOfTouchesRequired = 1;
        _doubleTapGesture.numberOfTapsRequired = 2;
    }
    return _doubleTapGesture;
}

- (ReplayerBrightness *)brightnessAdjust {
    if (!_brightnessAdjust) {
        _brightnessAdjust = [ReplayerBrightness sharedInstance];
    }
    return _brightnessAdjust;
}

#pragma mark - setter

- (void)setDelegate:(id<ReplayerDelegate>)pDelegate {
    if (delegate != pDelegate) {
        delegate = pDelegate;
        delegateRespondsCache.replayerContainerShouldBeGoBack       = [delegate respondsToSelector:@selector(replayer:goBackWithPlayedTime:)];
        delegateRespondsCache.replayerDidFinishTask                 = [delegate respondsToSelector:@selector(replayerDidFinishTask)];
        delegateRespondsCache.replayerDidDetectNetworkStatusChange  = [delegate respondsToSelector:@selector(replayerDidDetectNetworkStatusChange:withPlayedTime:)];
        delegateRespondsCache.replayerWillResignToBackground        = [delegate respondsToSelector:@selector(replayer:willBeResignedToBackgroundToSavePlayedTime:)];
        delegateRespondsCache.replayerDidBecomeActive               = [delegate respondsToSelector:@selector(replayerDidBecomeActiveToForeground:)];
        delegateRespondsCache.replayerDidReplayTask                 = [delegate respondsToSelector:@selector(replayerDidReplayTask:)];
    }
}

- (void)setStreamingURL:(NSString *)streamingURL {
    _streamingURL = streamingURL;
    
    if (_streamingURL && _streamingURL.length > 0) {
        [self p_addDeviceNotifications];
    }
}

- (void)setPlayTask:(ReplayerTask *)playTask {
    NSAssert(playTask, @"需要一个视频播放任务");
    _playTask = playTask;
    [self.playerPanel sendReplayerTask:_playTask];
    
    self.streamingURL = _playTask.streamingURL;
    self.seekTime = _playTask.seekTime;
    self.videoCapacity = _playTask.videoCapacity;
    self.checkCellular = _playTask.isCheckCellularEnable;
}

- (void)setPlayerPanel:(UIView *)playerPanel {
    if (_playerPanel) {
        return;
    }
    _playerPanel = playerPanel;
    _playerPanel.delegate = self;
    [self addSubview:_playerPanel];
    
    [_playerPanel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}

- (void)setState:(ReplayerCurrentState)state {
    _state = state;
    
    NSLog(@"latest state : %lu",(unsigned long)_state);
    
    // 一旦进入加载动画，就启动播放时间监听，进入加载失败的倒计时loop
    if (_state == ReplayerCurrentStateBuffering) {
        [self.playerPanel loadingAnimation];
        self.timeout = 0;
        [self checkLoadingTimeout];
    } else {
        [self.playerPanel endLoadingAnimation];
        // 结束loading，回归正常
        if (self.loadingTimer) {
            dispatch_source_cancel(self.loadingTimer);
            self.loadingTimer = nil;
            self.timeout = 0;
        }
    }
    
    if (state == ReplayerCurrentStateFailedToLoad) {
        self.error = YES;
    } else if (state == ReplayerCurrentStatePlaying || state == ReplayerCurrentStateBuffering) {
        // 只用于隐藏视频开头的预览图
        [self.playerPanel playWithCurrentTask];
    } else if (state == ReplayerCurrentStateCompleted) {
        [self.playerPanel replayerDidEndStreaming];
    } else if (state == ReplayerCurrentStatePaused) {
        
    }
}

- (void)setPlayerItem:(AVPlayerItem *)playerItem {
    if (_playerItem == playerItem) {
        return;
    }
    if (playerItem) {
        _playerItem = playerItem;
        [self p_addObserversOnPlayerItem];
    } else {
        [self p_removeObserversOnEmptyPlayerItem];
        [self.playerPanel replayerPanelShows];
        _playerItem = playerItem;
    }
}

- (void)setVideoGravity:(ReplayerVideoGravity)videoGravity {
    _videoGravity = videoGravity;
    switch (videoGravity) {
        case ReplayerVideoGravityResize:
            self.playerLayer.videoGravity = self.p_videoGravity = AVLayerVideoGravityResize;
            break;
        case ReplayerVideoGravityResizeAspect:
            self.playerLayer.videoGravity = self.p_videoGravity = AVLayerVideoGravityResizeAspect;
            break;
        case ReplayerVideoGravityResizeAspectFill:
            self.playerLayer.videoGravity = self.p_videoGravity = AVLayerVideoGravityResizeAspectFill;
            break;
        default:
            break;
    }
}

- (void)setCheckCellular:(BOOL)checkCellular {
    _checkCellular = checkCellular;
    self.denyCellular = _checkCellular;
    if (_checkCellular) {
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(reachabilityDidChange:) name:kReachabilityChangedNotification object:nil];
        
        self.networkFlag = [Reachability reachabilityForInternetConnection];
        [self.networkFlag startNotifier];
        
        [self updateInterfaceWithReachability:self.networkFlag];
    }
}

- (void)setError:(BOOL)error {
    _error = error;
    if (_error) {
        [self.playerPanel replayerUnableToResumePlayingWithReason:ReplayerUnableToResumeReasonBufferEmpty];
    }
}

@end