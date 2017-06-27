//
//  ReplayerBrightness.m
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/6/1.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "ReplayerBrightness.h"
#import "ReplayerComposer.h"

@interface ReplayerBrightness ()

@property (nonatomic, strong) UIImageView *brightImageView;
@property (nonatomic, strong) UILabel *brightLabel;
@property (nonatomic, strong) UIView *brightAdjustView;
@property (nonatomic, copy) NSArray *adjustBlocksArr;

@end

@implementation ReplayerBrightness

#pragma mark - 生命周期 Singleton

+ (instancetype)sharedInstance{
    static ReplayerBrightness *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        [[UIApplication sharedApplication].keyWindow addSubview:sharedInstance];
    });
    return sharedInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

+ (id)copyWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (id)copy {
    return self;
}

#pragma mark init & layout

- (instancetype)init {
    if (self = [super init]) {
        // 构建一个类似音量调节的系统样式视图
        self.frame = CGRectMake(0, 0, 155, 155);
        self.layer.cornerRadius = 10;
        self.layer.masksToBounds = YES;
        
        UIToolbar *brightness = [[UIToolbar alloc] initWithFrame:self.bounds];
        brightness.alpha = 0.88;
        [self addSubview:brightness];
        
        self.brightImageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, 79, 76)];
        self.brightImageView.image = [UIImage imageNamed:@"brightness"];
        [self addSubview:self.brightImageView];
        
        self.brightLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 5, self.bounds.size.width, 30)];
        self.brightLabel.textAlignment = NSTextAlignmentCenter;
        self.brightLabel.text = @"亮度";
        self.brightLabel.textColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.0f];
        self.brightLabel.font = [UIFont boldSystemFontOfSize:16.0f];
        [self addSubview:self.brightLabel];
        
        self.brightAdjustView = [[UIView alloc] initWithFrame:CGRectMake(13, 132, self.bounds.size.width - 26, 7)];
        self.brightAdjustView.backgroundColor = [UIColor colorWithRed:0.25f green:0.22f blue:0.21f alpha:1.0f];
        [self addSubview:self.brightAdjustView];
        
        // 添加设备旋转通知
        [self updateDeviceOrientationNotification];
        [self updateBrighnessObserver];
        [self adjustBlocks];
        
        self.alpha = 0.0f;
    }
    return self;
}

- (void)layoutSubviews {
    [super layoutSubviews];
    self.brightImageView.center = CGPointMake(155.0/2, 155.0/2);
    self.center = CGPointMake(ScreenWidth / 2.0f, ScreenHeight / 2.0f);
}

/*** 应该不会走 ***/
- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    [[UIScreen mainScreen] removeObserver:self forKeyPath:@"brightness"];
}

/*** 添加亮度展示方块 ***/
- (void)adjustBlocks {
    
    NSMutableArray *tempArr = [NSMutableArray arrayWithCapacity:16];
    
    CGFloat blockW = (self.brightAdjustView.bounds.size.width - 17) / 16;
    CGFloat blockH = 5;
    CGFloat blockY = 1;
    
    for (NSInteger i = 0; i < 16; i++) {
        CGFloat blockX = i * (blockW + 1) + 1;
        UIView *block = [[UIView alloc] init];
        block.backgroundColor = [UIColor whiteColor];
        block.frame = CGRectMake(blockX, blockY, blockW, blockH);
        [self.brightAdjustView addSubview:block];
        [tempArr addObject:block];
    }
    
    self.adjustBlocksArr = [tempArr copy];
    [self updateBrightness:[UIScreen mainScreen].brightness];
}

#pragma mark - noti & kvo

- (void)updateDeviceOrientationNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(deviceOrientationDidChange:) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)updateBrighnessObserver {
    [[UIScreen mainScreen] addObserver:self forKeyPath:@"brightness" options:NSKeyValueObservingOptionNew context:nil];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    [self brightnessAppear];
    [self updateBrightness:[[change objectForKey:NSKeyValueChangeNewKey] floatValue]];
}

#pragma mark - Notification SEL

- (void)deviceOrientationDidChange:(NSNotification *)noti {
    [self setNeedsLayout];
    [self layoutIfNeeded];
}

#pragma mark - Update Brightness

- (void)updateBrightness:(CGFloat)brightnessValue {
    // brightnessvalue : 0.0 ~ 1.0
    NSInteger level = brightnessValue * 15.0f;
    
    for (NSInteger i = 0; i < self.adjustBlocksArr.count; i++) {
        UIView *element = self.adjustBlocksArr[i];
        if (i <= level) {
            element.hidden = NO;
        } else {
            element.hidden = YES;
        }
    }
}

- (void)brightnessAppear {
    if (self.alpha == 0.0f) {
        self.alpha = 1.0f;
        dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2.0f * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
            [self brightnessDisappear];
        });
    }
}

- (void)brightnessDisappear {
    if (self.alpha == 1.0f) {
        [UIView animateWithDuration:0.8 animations:^{
            self.alpha = 0.0f;
        } completion:NULL];
    }
}

#pragma mark - setter

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    _statusBarHidden = statusBarHidden;
//    [[UIApplication sharedApplication] setStatusBarHidden:_statusBarHidden withAnimation:UIStatusBarAnimationFade];
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [[window rep_getCurrentViewController] setNeedsStatusBarAppearanceUpdate];
}

@end
