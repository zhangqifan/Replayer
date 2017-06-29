//
//  ReplayerPanel.m
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/5/31.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "ReplayerPanel.h"
#import "ReplayerComposer.h"

#define kScale ScreenWidth/375.0

static const CGFloat ReplayerUpperViewHeight            = 40.0f;
static const CGFloat ReplayerBelowViewHeight            = 40.0f;
NSTimeInterval ReplayerPanelKeepToActivateTimeInterval  = 5.0f;

@interface ReplayerPanel () <UIGestureRecognizerDelegate>

/*** 播放控制底层视图（不包括需要单独显示的控件） ***/
@property (nonatomic, strong) UIView *containerView;

/*** 控制板上部 ***/
@property (nonatomic, strong) UIView *upperView;

/*** 返回/退出全屏 ***/
@property (nonatomic, strong) UIImageView *backImageView;
@property (nonatomic, strong) UIView *backView;

/*** 视频标题 ***/
@property (nonatomic, strong) UILabel *videoTitleLabel;

/*** 控制板下部 ***/
@property (nonatomic, strong) UIView *belowView;

/*** 上层&下层的渐变layer ***/
@property (nonatomic, strong) UIImageView *upperGradient;
@property (nonatomic, strong) UIImageView *belowGradient;

/*** 播放按钮 ***/
@property (nonatomic, strong) UIButton *playButton;

/*** 当前播放时间 ***/
@property (nonatomic, strong) UILabel *currentTimeLabel;

/*** 播放进度条 ***/
@property (nonatomic, strong) ReplayerTrackSlider *playTrack;

/*** 视频全长时间 ***/
@property (nonatomic, strong) UILabel *durationLabel;

/*** 全屏/退出全屏按钮 ***/
@property (nonatomic, strong) UIButton *fullScreenButton;

/*** 加载动画视图 ***/
//@property (nonatomic, strong) ReplayerLoading *loadingView;
@property (nonatomic, strong) MMMaterialDesignSpinner *loadingView;

/*** 锁定/解锁屏幕按钮 ***/
@property (nonatomic, strong) UIButton *lockButton;

/*** 重新播放文字说明 ***/
@property (nonatomic, strong) UILabel *replayDescLabel;

/*** 重新播放按钮 ***/
@property (nonatomic, strong) UIButton *replayButton;

/*** 视频加载失败文字说明 ***/
@property (nonatomic, strong) UILabel *failedDescLabel;

/*** 视频加载失败按钮 ***/
@property (nonatomic, strong) UIButton *failedButton;

/*** 快进/快退视图 ***/
@property (nonatomic, strong) UIView *forwardView;

/*** 快进/快退标志 ***/
@property (nonatomic, strong) UIImageView *forwardImageView;

/*** 快进/快退至当前的时间 ***/
@property (nonatomic, strong) UILabel *draggedTimeLabel;

/*** 快进/快退至当前的时间进度条 ***/
@property (nonatomic, strong) UIProgressView *draggedProgress;

/*** 视频未开始播放的占位图 ***/
@property (nonatomic, strong) UIImageView *preImageView;

/*** 流量观看提示视图 ***/
@property (nonatomic, strong) UIView *usingCellularView;

/*** 流量观看提示文字 ***/
@property (nonatomic, strong) UILabel *usingCellularPromptLabel;

/*** 继续观看 ***/
@property (nonatomic, strong) UIButton *donotCareCellularButton;

/*** 是否全屏 ***/
@property (nonatomic, assign, getter=isFullScreen)      BOOL fullScreen;
/*** 是否显示控制板 ***/
@property (nonatomic, assign, getter=isActivatePanel)   BOOL activatePanel;
/*** 是否正在拖动进度 ***/
@property (nonatomic, assign, getter=isDragging)        BOOL dragging;
/*** 视频是否播放完毕 ***/
@property (nonatomic, assign, getter=isEndStreaming)    BOOL endStreaming;
/*** 播放错误 ***/
@property (nonatomic, assign, getter=isInError)         BOOL error;

/*** 控制板拿到的播放任务 ***/
@property (nonatomic, strong) ReplayerTask *playTask;

@end

@implementation ReplayerPanel

#pragma mark - 初始化和布局

- (instancetype)init {
    self = [super init];
    if (self) {
    
        [self addSubview:self.containerView];
        [self.containerView insertSubview:self.upperView atIndex:2];
        [self.containerView insertSubview:self.belowView atIndex:0];
        
        [self.upperView addSubview:self.upperGradient];
        [self.belowView addSubview:self.belowGradient];
        
        [self.containerView addSubview:self.lockButton];
        [self.upperView addSubview:self.backView];
        [self.upperView addSubview:self.videoTitleLabel];
        [self.belowView addSubview:self.playButton];
        [self.belowView addSubview:self.currentTimeLabel];
        [self.belowView addSubview:self.playTrack];
        [self.belowView addSubview:self.durationLabel];
        [self.belowView addSubview:self.fullScreenButton];
        
        [self addSubview:self.preImageView];
        
        [self addSubview:self.loadingView];
        
        [self addSubview:self.forwardView];
        [self.forwardView addSubview:self.forwardImageView];
        [self.forwardView addSubview:self.draggedTimeLabel];
        [self.forwardView addSubview:self.draggedProgress];
        
        [self.containerView insertSubview:self.usingCellularView atIndex:1];
        [self.usingCellularView addSubview:self.usingCellularPromptLabel];
        [self.usingCellularView addSubview:self.donotCareCellularButton];
        
        [self addSubview:self.replayDescLabel];
        [self addSubview:self.replayButton];
        [self addSubview:self.failedDescLabel];
        [self addSubview:self.failedButton];
        
        // 设定控件约束
        [self p_setupLayout];
        
        // 控件默认参数
        [self resetReplayerPanel];
    }
    return self;
}

- (void)p_setupLayout {
    [self.containerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.upperView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.containerView.mas_top);
        make.left.equalTo(self.containerView.mas_left);
        make.right.equalTo(self.containerView.mas_right);
        make.height.mas_equalTo(ReplayerUpperViewHeight);
    }];
    
    [self.belowView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.equalTo(self.containerView.mas_bottom);
        make.left.equalTo(self.containerView.mas_left);
        make.right.equalTo(self.containerView.mas_right);
        make.height.mas_equalTo(ReplayerBelowViewHeight);
    }];
    
    [self.upperGradient mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.belowGradient mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.backView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.upperView.mas_left).offset(10);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(35);
        make.centerY.equalTo(self.upperView);
    }];
    
    [self.backImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.backView);
        make.centerY.equalTo(self.backView);
        make.width.mas_equalTo(35);
        make.height.mas_equalTo(18);
    }];
    
    [self.videoTitleLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.upperView);
        make.centerY.equalTo(self.backView.mas_centerY);
        make.left.equalTo(self.upperView).offset(45);
        make.right.mas_equalTo(-(35+10));
    }];
    
    [self.playButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.belowView).offset(10);
        make.width.mas_equalTo(45);
        make.height.mas_equalTo(25);
        make.centerY.equalTo(self.belowView.mas_centerY);
    }];
    
    [self.fullScreenButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.belowView).offset(-10);
        make.width.mas_equalTo(45);
        make.height.mas_equalTo(25);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
    
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playButton.mas_right);
        make.centerY.equalTo(self.playButton.mas_centerY);
        make.width.mas_equalTo(55);
    }];
    
    [self.durationLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.fullScreenButton.mas_left);
        make.width.mas_equalTo(55);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
    
    [self.playTrack mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).offset(5);
        make.right.equalTo(self.durationLabel.mas_left).offset(-5);
        make.height.equalTo(self.belowView.mas_height);
        make.centerY.equalTo(self.playButton.mas_centerY);
    }];
    
    [self.replayDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(-20*kScale);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
    }];
    
    [self.replayButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(20*kScale);
        make.height.mas_equalTo(34*kScale);
        make.width.mas_equalTo(100*kScale);
    }];
    
    [self.failedDescLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(-20*kScale);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
    }];
    
    [self.failedButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self).offset(20*kScale);
        make.height.mas_equalTo(34*kScale);
        make.width.mas_equalTo(100*kScale);
    }];
    
    [self.loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self);
        make.width.height.mas_equalTo(40);
    }];
    
    [self.forwardView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self);
        make.centerY.equalTo(self);
        make.width.mas_equalTo(150);
        make.height.mas_equalTo(100);
    }];
    
    [self.forwardImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.forwardView);
        make.top.mas_equalTo(20);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(24);
    }];

    [self.draggedTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.forwardImageView.mas_bottom).offset(10);
        make.left.equalTo(self.forwardView).offset(5);
        make.right.equalTo(self.forwardView).offset(-5);
        make.height.mas_equalTo(15);
    }];
    
    [self.draggedProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.bottom.mas_equalTo(-8);
        make.left.mas_equalTo(5);
        make.right.mas_equalTo(-5);
    }];
    
    [self.preImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.usingCellularView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.usingCellularPromptLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.usingCellularView);
        make.centerY.equalTo(self.usingCellularView).offset(-10*kScale);
        make.left.mas_equalTo(10);
        make.right.mas_equalTo(-10);
    }];
    
    [self.donotCareCellularButton mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.usingCellularView);
        make.centerY.equalTo(self.usingCellularView).offset(50*kScale);
        make.height.mas_equalTo(34*kScale);
        make.width.mas_equalTo(100*kScale);
    }];
}

#pragma mark - Private

/*** 返回进度条上滑块的位置信息 ***/
- (CGRect)sliderBlockRect {
    return [self.playTrack trackBlockRect];
}

/*** 显示控制板 ***/
- (void)activatePanel {
    self.activatePanel = YES;
    self.upperView.alpha = 1.0f;
    self.belowView.alpha = 1.0f;
    [ReplayerStatusBarManager sharedInstance].statusBarHidden = NO;
}

/*** 隐藏控制板 ***/
- (void)inactivatePanel {
    self.activatePanel = NO;
    self.upperView.alpha = 0.0f;
    self.belowView.alpha = 0.0f;
    [ReplayerStatusBarManager sharedInstance].statusBarHidden = YES;
}

/*** 开启自动隐藏控制板功能 ***/
- (void)activateAutoDisappearThePanel {
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(replayerPanelDisappears) object:nil];
    [self performSelector:@selector(replayerPanelDisappears) withObject:nil afterDelay:ReplayerPanelKeepToActivateTimeInterval];
}

/*** 视频加载失败 ***/
- (void)replayerLoadedDisabledTask {
    self.failedButton.hidden = NO;
    self.failedDescLabel.hidden = NO;
    [self replayerTransformsPlayButtonStatus:NO];
    [self activatePanel];
    [self endLoadingAnimation];
}

#pragma mark - dealloc

- (void)dealloc {
    [[UIDevice currentDevice] endGeneratingDeviceOrientationNotifications];
}

#pragma mark - 扩展方法

/*** 初始化/重置播放器控制板 ***/
- (void)resetReplayerPanel {
    [self.loadingView stopAnimating];
    self.videoTitleLabel.text       = @"";
    self.currentTimeLabel.text      = @"00:00";
    self.durationLabel.text         = @"00:00";
    self.replayDescLabel.hidden     = YES;
    self.replayButton.hidden        = YES;
    self.failedDescLabel.hidden     = YES;
    self.failedButton.hidden        = YES;
    self.preImageView.alpha         = 1.0f;
    self.forwardView.hidden         = YES;
    self.playButton.selected        = NO;
    self.fullScreenButton.selected  = self.isFullScreen;
    self.activatePanel              = YES;
    self.upperView.alpha            = 1.0f;
    self.belowView.alpha            = 1.0f;
    self.usingCellularView.hidden   = YES;
    self.endStreaming               = NO;
    self.error                      = NO;
    [self.playTrack setPlayedValue:0.0f animated:YES];
    [self.playTrack setBufferValue:0.0f animated:YES];
}

/*** 将视频任务给控制板呈现数据，标题/时长 等 ***/
- (void)sendReplayerTask:(ReplayerTask *)task {
    if (!task.coverImage && !task.coverImageURL) {
        self.preImageView.alpha = 0.0f;
    }
    self.videoTitleLabel.text = task.videoTitle;
}

/**
 @group methods@ 视频控制板的显示状况
 - replayerPanelShows                   : 显示控制板
 - replayerPanelDisappears              : 隐藏控制板
 - replayerPanelChangesDisplayStatus    : 改变控制板的显示状态
 */
- (void)replayerPanelShows {
    [self replayerPanelCancelAutoChangeStatus];
    [UIView animateWithDuration:0.3 animations:^{
        [self activatePanel];
    } completion:^(BOOL finished) {
        [self activateAutoDisappearThePanel];
    }];
}

- (void)replayerPanelDisappears {
    [self replayerPanelCancelAutoChangeStatus];
    [UIView animateWithDuration:0.3 animations:^{
        [self inactivatePanel];
    } completion:^(BOOL finished) {
        
    }];
}

- (void)replayerPanelChangesDisplayStatus {
    if (self.isActivatePanel) {
        [self replayerPanelDisappears];
    } else {
        [self replayerPanelShows];
    }
}

/*** 取消自动隐藏控制板 ***/
- (void)replayerPanelCancelAutoChangeStatus {
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

/*** 控制板自动隐藏时间，默认 7 秒钟 ***/
- (NSTimeInterval)replayerPanelKeepToActivateTimeInterval {
    return ReplayerPanelKeepToActivateTimeInterval;
}

/*** 视频播放完毕 ***/
- (void)replayerDidEndStreaming {
    self.endStreaming = YES;
    self.replayDescLabel.hidden = NO;
    self.replayButton.hidden = NO;
    [self replayerTransformsPlayButtonStatus:NO];
    [self activatePanel];
    [self endLoadingAnimation];
}

/*** 视频因源失效/缓冲无法加载/网络中断造成的视频中途播放问题 ***/
- (void)replayerUnableToResumePlayingWithReason:(ReplayerUnableToResumeReason)cannotResumeReason {
    self.error = YES;
    if (cannotResumeReason == ReplayerUnableToResumeReasonBufferEmpty) {
        self.failedDescLabel.text = @"视频加载超时，请重试";
    } else if (cannotResumeReason == ReplayerUnableToResumeReasonNoNetwork) {
        self.failedDescLabel.text = @"网络中断，请连接网络后再试";
    } else if (cannotResumeReason == ReplayerUnableToResumeReasonSourceGone) {
        self.failedDescLabel.text = @"视频源已失效";
    }
    [self replayerLoadedDisabledTask];
}

/**
 滑动至当前时长
 
 @param currentSecond 当前时长
 @param totalSeconds 视频总时长
 @param isForward 滑动方向，向后滑动为 YES
 */
- (void)slideToCurrentTime:(CGFloat)currentSecond fullSizeSeconds:(CGFloat)totalSeconds isForward:(BOOL)isForward {
    [self endLoadingAnimation];
    
    self.forwardView.hidden = NO;
    if (isForward) {
        self.forwardImageView.image = GetBundleAsset(@"replayer_fast_forward");
    } else {
        self.forwardImageView.image = GetBundleAsset(@"replayer_fast_backward");
    }
    
    self.dragging = YES;
    
    // 对取得的秒数进行处理，如不满足一小时，则显示格式为 [00:00] ；如满足一小时，则显示格式为 [00:00:00]
    int hour = totalSeconds / 3600;
    if (hour == 0) {
        int nowSecond   = (int)currentSecond % 60;
        int nowMinute   = (int)(currentSecond / 60) % 60;
        
        int seconds     = (int)totalSeconds % 60;
        int minutes     = (int)(totalSeconds /60) % 60;
        
        NSString *nowTime   = [NSString stringWithFormat:@"%02d:%02d",nowMinute,nowSecond];
        NSString *totalTime = [NSString stringWithFormat:@"%02d:%02d",minutes,seconds];
        CGFloat slideValue = currentSecond / totalSeconds;
        
        NSString *dragTime = [NSString stringWithFormat:@"%@ / %@",nowTime,totalTime];;
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:dragTime];
        [attrStr addAttribute:NSForegroundColorAttributeName value:RGBA(255, 255, 255, 1) range:NSMakeRange(0, nowTime.length)];
        [attrStr addAttribute:NSForegroundColorAttributeName value:RGBA(255, 255, 255, 0.6) range:NSMakeRange(nowTime.length+1, totalTime.length+2)];
        self.draggedTimeLabel.attributedText = attrStr;
        self.draggedTimeLabel.textAlignment = NSTextAlignmentCenter;
        [self.draggedProgress setProgress:slideValue animated:NO];
        
    } else {
        int nowSecond   = (int)currentSecond % 60;
        int nowMinute   = (int)(currentSecond / 60) % 60;
        int nowHour     = (int)currentSecond / 3600;
        
        int seconds     = (int)totalSeconds % 60;
        int minutes     = (int)(totalSeconds /60) % 60;
        int hours       = (int)totalSeconds / 3600;
        
        NSString *nowTime   = [NSString stringWithFormat:@"%02d:%02d:%02d",nowHour,nowMinute,nowSecond];
        NSString *totalTime = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes,seconds];
        CGFloat slideValue = currentSecond / totalSeconds;
        
        NSString *dragTime = [NSString stringWithFormat:@"%@ / %@",nowTime,totalTime];;
        
        NSMutableAttributedString *attrStr = [[NSMutableAttributedString alloc] initWithString:dragTime];
        [attrStr addAttribute:NSForegroundColorAttributeName value:RGBA(255, 255, 255, 1) range:NSMakeRange(0, nowTime.length)];
        [attrStr addAttribute:NSForegroundColorAttributeName value:RGBA(255, 255, 255, 0.6) range:NSMakeRange(nowTime.length+1, totalTime.length+2)];
        self.draggedTimeLabel.attributedText = attrStr;
        self.draggedTimeLabel.textAlignment = NSTextAlignmentCenter;
        [self.draggedProgress setProgress:slideValue animated:NO];
    }
}

/**
 正常播放状态的时刻/时长/进度条更新
 
 @param currentSecond 当前已播放时长
 @param totalSeconds 视频总时长
 @param playedPercent 进度条已播放比例
 */
- (void)replayerPlaysNormally:(CGFloat)currentSecond fullSizeSeconds:(CGFloat)totalSeconds sliderPlayedPercent:(CGFloat)playedPercent {
    // 对取得的秒数进行处理，如不满足一小时，则显示格式为 [00:00] ；如满足一小时，则显示格式为 [00:00:00]
    int hour = totalSeconds / 3600;
    if (hour == 0) {
        int nowSecond   = (int)currentSecond % 60;
        int nowMinute   = (int)(currentSecond / 60) % 60;
        
        int seconds     = (int)totalSeconds % 60;
        int minutes     = (int)(totalSeconds /60) % 60;
        
        self.currentTimeLabel.text  = [NSString stringWithFormat:@"%02d:%02d",nowMinute,nowSecond];
        self.durationLabel.text     = [NSString stringWithFormat:@"%02d:%02d",minutes,seconds];
    } else {
        int nowSecond   = (int)currentSecond % 60;
        int nowMinute   = (int)(currentSecond / 60) % 60;
        int nowHour     = (int)currentSecond / 3600;
        
        int seconds     = (int)totalSeconds % 60;
        int minutes     = (int)(totalSeconds /60) % 60;
        int hours       = (int)totalSeconds / 3600;
        
        self.currentTimeLabel.text  = [NSString stringWithFormat:@"%02d:%02d:%02d",nowHour,nowMinute,nowSecond];
        self.durationLabel.text     = [NSString stringWithFormat:@"%02d:%02d:%02d",hours,minutes,seconds];
    }
    
    if (!self.isDragging) {
        [self.playTrack setPlayedValue:playedPercent animated:YES];
    }
}

/**
 设置缓冲进度
 
 @param bufferProgress 缓冲进度
 */
- (void)replayerSetBufferProgress:(CGFloat)bufferProgress {
    [self.playTrack setBufferValue:bufferProgress animated:YES];
}

/*** 停止滑动并释放手势 ***/
- (void)replayerEndSliding {
    [self activateAutoDisappearThePanel];
}

/*** 隐藏快进快退视图 ***/
- (void)hideForwardView {
    self.dragging = NO;
    self.forwardView.hidden = YES;
}

/*** 加载动画 ***/
- (void)loadingAnimation {
    [self.loadingView startAnimating];
}

/*** 从xxx时间开始播放的提示 ***/
- (void)toastFromSeekTime:(NSInteger)seekTime {
    
    CSToastStyle *style = [[CSToastStyle alloc] initWithDefaultStyle];
    style.backgroundColor = RGBA(0, 0, 0, 0.6);
    style.titleFont = [UIFont systemFontOfSize:14.0f];
    
    NSInteger hour = seekTime / 3600;
    if (hour == 0) {
        int nowSecond   = (int)seekTime % 60;
        int nowMinute   = (int)(seekTime / 60) % 60;

        if (self.isFullScreen) {
            [self makeToast:[NSString stringWithFormat:@"您上次观看至%02d:%02d，从此处继续播放",nowMinute,nowSecond] duration:3.0f position:CSToastPositionBottom style:style];
        } else {
            [self makeToast:[NSString stringWithFormat:@"从%02d:%02d处继续播放",nowMinute,nowSecond] duration:3.0f position:CSToastPositionBottom style:style];
        }
    } else {
        int nowSecond   = (int)seekTime % 60;
        int nowMinute   = (int)(seekTime / 60) % 60;
        int nowHour     = (int)seekTime / 3600;
        
        if (self.isFullScreen) {
            [self makeToast:[NSString stringWithFormat:@"您上次观看至%02d:%02d:%02d，从此处继续播放",nowHour,nowMinute,nowSecond] duration:3.0f position:CSToastPositionBottom style:style];
        } else {
            [self makeToast:[NSString stringWithFormat:@"从%02d:%02d:%02d处继续播放",nowHour,nowMinute,nowSecond] duration:3.0f position:CSToastPositionBottom style:style];
        }
    }
}

/*** 停止加载动画 ***/
- (void)endLoadingAnimation {
    [self.loadingView stopAnimating];
}

/*** 开始播放 ***/
- (void)playWithCurrentTask {
    [UIView animateWithDuration:0.3 animations:^{
        self.preImageView.alpha = 0.0f;
    } completion:^(BOOL finished) {
        
    }];
}

/*** 是否进入了全屏模式 ***/
- (void)replayerDidBecomeFullScreen:(BOOL)isFullScreen {
    self.fullScreen = isFullScreen;
    self.fullScreenButton.selected = isFullScreen;
    [self.upperView mas_updateConstraints:^(MASConstraintMaker *make) {
        if (self.fullScreen) {
            make.height.mas_equalTo(ReplayerUpperViewHeight+20);
        } else {
            make.height.mas_equalTo(ReplayerUpperViewHeight);
        }
    }];
    
    [self.backView mas_updateConstraints:^(MASConstraintMaker *make) {
        if (self.fullScreen) {
            make.centerY.equalTo(self.upperView).offset(10);
        } else {
            make.centerY.equalTo(self.upperView);
        }
    }];
    
    [self.videoTitleLabel updateConstraintsIfNeeded];
}

/*** 使用流量提醒 ***/
- (void)replayerDidUseCellular:(BOOL)useCellular {
    if (useCellular) {
        self.usingCellularView.hidden = NO;
        self.upperView.hidden = NO;
        [ReplayerStatusBarManager sharedInstance].statusBarHidden = NO;
    }
}

/*** 视频任务大小 ***/
- (void)replayerTaskCapacity:(NSNumber *)videoCapacity {
    NSString *capaLabel = @"";
    if (videoCapacity) {
        capaLabel = [NSString stringWithFormat:@"本视频共 %@MB 流量 \n 您目前不在 wifi 环境下，继续播放可能会产生流量费用",videoCapacity];
    } else {
        capaLabel = [NSString stringWithFormat:@"播放视频需要消耗数据流量 \n 您目前不在 wifi 环境下，继续播放可能会产生流量费用"];
    }
    NSMutableAttributedString *mutableAttr = [[NSMutableAttributedString alloc] initWithString:capaLabel];
    NSMutableParagraphStyle *pStyle = [[NSMutableParagraphStyle alloc] init];
    [pStyle setLineSpacing:6.0f];
    [mutableAttr addAttribute:NSParagraphStyleAttributeName value:pStyle range:NSMakeRange(0, capaLabel.length)];
    self.usingCellularPromptLabel.attributedText = mutableAttr;
    self.usingCellularPromptLabel.adjustsFontSizeToFitWidth = YES;
    self.usingCellularPromptLabel.textAlignment = NSTextAlignmentCenter;
}

/**
 更改播放按钮状态
 
 @param toPlay 是否调整为播放状态
 */
- (void)replayerTransformsPlayButtonStatus:(BOOL)toPlay {
    self.playButton.selected = toPlay;
}

/**
 更改屏幕锁定按钮状态
 
 @param toLock 是否调整为锁定状态
 */
- (void)replayerTransformsLockButtonStatus:(BOOL)toLock {
    self.lockButton.selected = toLock;
}

#pragma mark - 手势和响应方法

/*** 弹出vc或者视频退出全屏 ***/
- (void)popOrMakeFullScreenMinimize {
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:goBackAction:)]) {
        [self.delegate replayerPanel:self goBackAction:nil];
    }
}

/*** 点击播放/暂停 ***/
- (void)playButtonAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:doPlayAction:)]) {
        [self.delegate replayerPanel:self doPlayAction:sender];
    }
}

/*** 按钮强制进入/退出全屏 ***/
- (void)enterFullScreenAction:(UIButton *)sender {
    sender.selected = !sender.selected;
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:forceToFullScreenAction:)]) {
        [self.delegate replayerPanel:self forceToFullScreenAction:sender];
    }
}

/*** 锁定/解锁屏幕 ***/
- (void)lockAction:(UIButton *)sender {
    
}

/*** 使用流量播放 ***/
- (void)passToUseCellularAction:(UIButton *)sender {
    self.usingCellularView.hidden = YES;
    [self activateAutoDisappearThePanel];
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanelPassToUseCellular:)]) {
        [self.delegate replayerPanelPassToUseCellular:self];
    }
}

/*** 重播该任务 ***/
- (void)replayerToReplayTheTask:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:replayAction:)]) {
        [self.delegate replayerPanel:self replayAction:sender];
    }
}

/*** 加载或缓冲失败 ***/
- (void)replayerFailToLoadOrBufferTheTask:(UIButton *)sender {
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:failToLoadOrBuffer:)]) {
        [self.delegate replayerPanel:self failToLoadOrBuffer:sender];
    }
}

#pragma mark 滑杆事件

/*** trackSlider 准备开始滑动 ***/
- (void)trackSliderTouchBegan:(UISlider *)trackSlider {
    [self replayerPanelCancelAutoChangeStatus];
    [ReplayerStatusBarManager sharedInstance].statusBarHidden = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:progressBarTouchBegan:)]) {
        [self.delegate replayerPanel:self progressBarTouchBegan:trackSlider];
    }
}

/*** trackSlider 滑动值变化 ***/
- (void)trackSliderValueDidChange:(UISlider *)trackSlider {
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:progressBarValueChanged:)]) {
        [self.delegate replayerPanel:self progressBarValueChanged:trackSlider];
    }
}

/*** trackSlider 结束滑动 ***/
- (void)trackSliderTouchEnded:(UISlider *)trackSlider {
    self.forwardView.hidden = YES;
    self.dragging = NO;
    if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:progressBarTouchEnded:)]) {
        [self.delegate replayerPanel:self progressBarTouchEnded:trackSlider];
    }
}

/*** 在 trackSlider 上点选时间 ***/
- (void)trackSliderSeekToValue:(UITapGestureRecognizer *)ges {
    if ([ges.view isKindOfClass:[UISlider class]]) {
        UISlider *track = (UISlider *)ges.view;
        CGPoint point = [ges locationInView:track];
        CGFloat length = track.bounds.size.width;
        // 计算触摸的位置和长度的比例
        CGFloat tapLocation = point.x / length;
        if (self.delegate && [self.delegate respondsToSelector:@selector(replayerPanel:progressBarTapAction:)]) {
            [self.delegate replayerPanel:self progressBarTapAction:tapLocation];
        }
    }
}

/*** 滑动 trackSlider 其他地方，解决与整体播放器手势冲突问题 ***/
- (void)trackSliderPanGesture:(UIPanGestureRecognizer *)ges {
    return;
}

#pragma mark - UIGestureRecognizerDelegate

/*** 判断滑动的手势是否在滑块范围内，区域内其他手势的冲突 ***/
- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
    CGRect trackerRect = [self sliderBlockRect];
    CGPoint point = [touch locationInView:self.playTrack.playedTrack];
    if ([touch.view isKindOfClass:[UISlider class]]) {
        if (point.x <= trackerRect.origin.x + trackerRect.size.width && point.x >= trackerRect.origin.x) {
            return NO;
        }
    }
    return YES;
}

#pragma mark - setter

- (void)setFullScreen:(BOOL)fullScreen {
    _fullScreen = fullScreen;
    self.fullScreenButton.selected = _fullScreen;
    if (_fullScreen) {
        self.usingCellularPromptLabel.font = [UIFont systemFontOfSize:14.0f];
    } else {
        if ([UIScreen mainScreen].bounds.size.width <= 320.0f) {
            self.usingCellularPromptLabel.font = [UIFont systemFontOfSize:12.0f];
        }
    }
}

// 播放是否结束
- (void)setEndStreaming:(BOOL)endStreaming {
    _endStreaming = endStreaming;
    self.playTrack.userInteractionEnabled = !_endStreaming;
}

// 播放是否出现错误
- (void)setError:(BOOL)error {
    _error = error;
    self.playTrack.userInteractionEnabled = !_error;
}

#pragma mark - 各类控制板控件的 lazy load

- (UIView *)containerView {
    if (!_containerView) {
        _containerView = [UIView new];
        _containerView.backgroundColor = [UIColor clearColor];
    }
    return _containerView;
}

- (UIView *)upperView {
    if (!_upperView) {
        _upperView = [UIView new];
        _upperView.backgroundColor = [UIColor clearColor];
    }
    return _upperView;
}

- (UIImageView *)backImageView {
    if (!_backImageView) {
        _backImageView = [[UIImageView alloc] initWithImage:GetBundleAsset(@"replayer_back")];
        _backImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _backImageView;
}

- (UIView *)backView {
    if (!_backView) {
        _backView = [UIView new];
        _backView.backgroundColor = [UIColor clearColor];
        UITapGestureRecognizer *backOrMinimizeGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(popOrMakeFullScreenMinimize)];
        [_backView addGestureRecognizer:backOrMinimizeGesture];
        [_backView addSubview:self.backImageView];
    }
    return _backView;
}

- (UILabel *)videoTitleLabel {
    if (!_videoTitleLabel) {
        _videoTitleLabel = [UILabel new];
        _videoTitleLabel.textColor = [UIColor whiteColor];
        _videoTitleLabel.font = [UIFont boldSystemFontOfSize:18.0f];
        _videoTitleLabel.textAlignment = NSTextAlignmentCenter;
        _videoTitleLabel.numberOfLines = 1;
    }
    return _videoTitleLabel;
}

- (UIView *)belowView {
    if (!_belowView) {
        _belowView = [UIView new];
        _belowView.backgroundColor = [UIColor clearColor];
    }
    return _belowView;
}

- (UIImageView *)upperGradient {
    if (!_upperGradient) {
        _upperGradient = [[UIImageView alloc] initWithImage:GetBundleAsset(@"upper-gradient")];
        _upperGradient.contentMode = UIViewContentModeScaleToFill;
    }
    return _upperGradient;
}

- (UIImageView *)belowGradient {
    if (!_belowGradient) {
        _belowGradient = [[UIImageView alloc] initWithImage:GetBundleAsset(@"below-gradient")];
        _belowGradient.contentMode = UIViewContentModeScaleToFill;
    }
    return _belowGradient;
}

- (UIButton *)playButton {
    if (!_playButton) {
        _playButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playButton setImage:GetBundleAsset(@"replayer_play") forState:UIControlStateNormal];
        [_playButton setImage:GetBundleAsset(@"replayer_pause") forState:UIControlStateSelected];
        [_playButton addTarget:self action:@selector(playButtonAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playButton;
}

- (UILabel *)currentTimeLabel {
    if (!_currentTimeLabel) {
        _currentTimeLabel = [UILabel new];
        _currentTimeLabel.textColor = [UIColor whiteColor];
        _currentTimeLabel.font = [UIFont systemFontOfSize:12.0f];
        _currentTimeLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _currentTimeLabel;
}

- (ReplayerTrackSlider *)playTrack {
    if (!_playTrack) {
        _playTrack = [[ReplayerTrackSlider alloc] init];
        _playTrack.playedTintColor = RGBA(255, 255, 255, 1);
        _playTrack.bufferedTintColor = RGBA(255, 255, 255, 0.6);
        _playTrack.trackTintColor = RGBA(255, 255, 255, 0.3);
        [_playTrack setSliderBlock:GetBundleAsset(@"replayer_track_point") forState:UIControlStateNormal];
        [_playTrack setSliderBlock:GetBundleAsset(@"replayer_track_point") forState:UIControlStateHighlighted];
        
        [_playTrack.playedTrack addTarget:self action:@selector(trackSliderTouchBegan:) forControlEvents:UIControlEventTouchDown];
        [_playTrack.playedTrack addTarget:self action:@selector(trackSliderValueDidChange:) forControlEvents:UIControlEventValueChanged];
        [_playTrack.playedTrack addTarget:self action:@selector(trackSliderTouchEnded:) forControlEvents:UIControlEventTouchUpInside|UIControlEventTouchUpOutside|UIControlEventTouchCancel];
        
        UITapGestureRecognizer *tapToSeekTime = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(trackSliderSeekToValue:)];
        [_playTrack.playedTrack addGestureRecognizer:tapToSeekTime];
        
        UIPanGestureRecognizer *panToAvoidOtherGestures = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(trackSliderPanGesture:)];
        panToAvoidOtherGestures.delegate = self;
        [panToAvoidOtherGestures setMaximumNumberOfTouches:1];
        [panToAvoidOtherGestures setDelaysTouchesBegan:YES];
        [panToAvoidOtherGestures setDelaysTouchesEnded:YES];
        [panToAvoidOtherGestures setCancelsTouchesInView:YES];
        
        [_playTrack.playedTrack addGestureRecognizer:panToAvoidOtherGestures];
    }
    return _playTrack;
}

- (UILabel *)durationLabel {
    if (!_durationLabel) {
        _durationLabel = [UILabel new];
        _durationLabel.textColor = [UIColor whiteColor];
        _durationLabel.font = [UIFont systemFontOfSize:12.0f];
        _durationLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _durationLabel;
}

- (UIButton *)fullScreenButton {
    if (!_fullScreenButton) {
        _fullScreenButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullScreenButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [_fullScreenButton setImage:GetBundleAsset(@"replayer_full_screen") forState:UIControlStateNormal];
        [_fullScreenButton setImage:GetBundleAsset(@"replayer_16_9") forState:UIControlStateSelected];
        [_fullScreenButton addTarget:self action:@selector(enterFullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullScreenButton;
}

- (MMMaterialDesignSpinner *)loadingView {
    if (!_loadingView) {
        _loadingView = [[MMMaterialDesignSpinner alloc] init];
        _loadingView.lineWidth = 1.5f;
        _loadingView.tintColor = RGBA(255, 255, 255, 1);
    }
    return _loadingView;
}

- (UIButton *)lockButton {
    if (!_lockButton) {
        _lockButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_lockButton.imageView setContentMode:UIViewContentModeScaleAspectFit];
        [_lockButton setImage:GetBundleAsset(@"replayer_full_screen") forState:UIControlStateNormal];
        [_lockButton setImage:GetBundleAsset(@"replayer_16_9") forState:UIControlStateSelected];
        [_lockButton addTarget:self action:@selector(lockAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _lockButton;
}

- (UILabel *)replayDescLabel {
    if (!_replayDescLabel) {
        _replayDescLabel = [[UILabel alloc] init];
        _replayDescLabel.text = @"视频播放完毕";
        _replayDescLabel.textColor = [UIColor whiteColor];
        _replayDescLabel.font = [UIFont systemFontOfSize:14.0f];
        _replayDescLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _replayDescLabel;
}

- (UIButton *)replayButton {
    if (!_replayButton) {
        _replayButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_replayButton setTitle:@"重新播放" forState:UIControlStateNormal];
        [_replayButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [_replayButton setTitleColor:RGBA(255, 255, 255, 1) forState:UIControlStateNormal];
        _replayButton.layer.cornerRadius = 17.0*kScale;
        _replayButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
        _replayButton.layer.borderWidth = 1;
        [_replayButton addTarget:self action:@selector(replayerToReplayTheTask:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _replayButton;
}

- (UILabel *)failedDescLabel {
    if (!_failedDescLabel) {
        _failedDescLabel = [[UILabel alloc] init];
        _failedDescLabel.text = @"视频加载失败，点击重试";
        _failedDescLabel.textColor = [UIColor whiteColor];
        _failedDescLabel.font = [UIFont systemFontOfSize:14.0f];
        _failedDescLabel.textAlignment = NSTextAlignmentCenter;
    }
    return _failedDescLabel;
}

- (UIButton *)failedButton {
    if (!_failedButton) {
        _failedButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_failedButton setTitle:@"重 试" forState:UIControlStateNormal];
        [_failedButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [_failedButton setTitleColor:RGBA(255, 255, 255, 1) forState:UIControlStateNormal];
        _failedButton.layer.cornerRadius = 17.0*kScale;
        _failedButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
        _failedButton.layer.borderWidth = 1;
        [_failedButton addTarget:self action:@selector(replayerFailToLoadOrBufferTheTask:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _failedButton;
}

- (UIView *)forwardView {
    if (!_forwardView) {
        _forwardView = [UIView new];
        _forwardView.backgroundColor = RGBA(0, 0, 0, 0.6);
        _forwardView.layer.cornerRadius = 5.0f;
    }
    return _forwardView;
}

- (UIImageView *)forwardImageView {
    if (!_forwardImageView) {
        _forwardImageView = [[UIImageView alloc] init];
        _forwardImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _forwardImageView;
}

- (UILabel *)draggedTimeLabel {
    if (!_draggedTimeLabel) {
        _draggedTimeLabel = [UILabel new];
        _draggedTimeLabel.font = [UIFont systemFontOfSize:13.0f];
    }
    return _draggedTimeLabel;
}

- (UIProgressView *)draggedProgress {
    if (!_draggedProgress) {
        _draggedProgress = [[UIProgressView alloc] init];
        [_draggedProgress setProgressTintColor:[UIColor whiteColor]];
        [_draggedProgress setTrackTintColor:[UIColor blackColor]];
    }
    return _draggedProgress;
}

- (UIImageView *)preImageView {
    if (!_preImageView) {
        _preImageView = [[UIImageView alloc] init];
        _preImageView.contentMode = UIViewContentModeScaleAspectFit;
    }
    return _preImageView;
}

- (UIView *)usingCellularView {
    if (!_usingCellularView) {
        _usingCellularView = [UIView new];
        _usingCellularView.backgroundColor = [UIColor blackColor];
    }
    return _usingCellularView;
}

- (UILabel *)usingCellularPromptLabel {
    if (!_usingCellularPromptLabel) {
        _usingCellularPromptLabel = [UILabel new];
        _usingCellularPromptLabel.numberOfLines = 2;
        _usingCellularPromptLabel.textColor = [UIColor whiteColor];
        if ([UIScreen mainScreen].bounds.size.width <= 320.0f) {
            self.usingCellularPromptLabel.font = [UIFont systemFontOfSize:12.0f];
        } else {
            self.usingCellularPromptLabel.font = [UIFont systemFontOfSize:13.0f];
        }
    }
    return _usingCellularPromptLabel;
}

- (UIButton *)donotCareCellularButton {
    if (!_donotCareCellularButton) {
        _donotCareCellularButton = [UIButton buttonWithType:UIButtonTypeCustom];
        [_donotCareCellularButton setTitle:@"继 续" forState:UIControlStateNormal];
        [_donotCareCellularButton.titleLabel setFont:[UIFont boldSystemFontOfSize:14.0f]];
        [_donotCareCellularButton setTitleColor:RGBA(255, 255, 255, 1) forState:UIControlStateNormal];
        _donotCareCellularButton.layer.cornerRadius = 17.0*kScale;
        _donotCareCellularButton.layer.borderColor = RGBA(255, 255, 255, 1).CGColor;
        _donotCareCellularButton.layer.borderWidth = 1;
        [_donotCareCellularButton addTarget:self action:@selector(passToUseCellularAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _donotCareCellularButton;
}

@end
