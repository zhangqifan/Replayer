//
//  ReplayerViewController.m
//  ReplayerDemo
//
//  Created by qifan.zhang on 2017/6/26.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "ReplayerViewController.h"
#import "ReplayerComposer.h"

@interface ReplayerViewController () <ReplayerDelegate>

@property (nonatomic, strong) Replayer *replayer;
@property (nonatomic, strong) ReplayerTask *replayerTask;
//@property (nonatomic, strong) ReplayerPanel

@end

@implementation ReplayerViewController

#pragma mark - Life cycle

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self.navigationController setNavigationBarHidden:YES animated:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.navigationController.interactivePopGestureRecognizer.delegate = (id)self;
    
    // setup replayer
    
    UIView *topBackground = [UIView new];
    topBackground.backgroundColor = [UIColor blackColor];
    [self.view addSubview:topBackground];
    
    [topBackground mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.view);
        make.leading.and.trailing.equalTo(self.view);
        make.height.mas_equalTo(20);
    }];
    
    [self setupReplayer];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - Status bar

- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (BOOL)prefersStatusBarHidden {
    return [ReplayerStatusBarManager sharedInstance].isStatusBarHidden;
}

#pragma mark - Setup Replayer

- (void)setupReplayer {
    self.replayer = [[Replayer alloc] init];
    self.replayer.delegate = self;
    if (self.playingType == VideoPlayingTypeLocalVideo || self.playingType == VideoPlayingTypeBeforeReplay || self.playingType == VideoPlayingTypeFullFeatures || self.playingType == VideoPlayingTypeResume) {
        [self.replayer replayerUsesDefaultPanelWithTask:self.replayerTask];
    }
    [self.view addSubview:self.replayer];
    
    [self.replayer mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(20);
        make.leading.and.trailing.equalTo(self.view);
        make.height.mas_equalTo([UIScreen mainScreen].bounds.size.width * (9.0/16.0));
    }];
    
    [self.replayer playInstantlyWhenPrepared];
}

#pragma mark - Replayer Delegate

- (void)replayerDidGoBack:(Replayer *)replayer {
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - Getter

- (ReplayerTask *)replayerTask {
    if (!_replayerTask) {
        _replayerTask = [[ReplayerTask alloc] init];
        _replayerTask.videoTitle = @"HLS测试视频";
        _replayerTask.streamingURL = self.videoSourceStr;
        _replayerTask.checkCellularEnable = YES;
        _replayerTask.videoIdentifier = @"apple_bippop_test_video";
        _replayerTask.cachePlayback = YES;
        _replayerTask.seekTime = [ReplayerPlaybackCache fetchPlaybackMomentByVideoIdentifier:_replayerTask.videoIdentifier];
        
        if (self.playingType == VideoPlayingTypeResume) {
            // 从视频第20秒开始播放
            _replayerTask.seekTime = 20;
        }
        
    }
    return _replayerTask;
}

@end
