//
//  ReplayerTrackSlider.m
//  ReplayerTrackSlider
//
//  Created by qifan.zhang on 2017/6/1.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "ReplayerTrackSlider.h"
#import <Masonry/Masonry.h>

@class ReplayerSlider;

static const CGFloat ReplayerSliderAndBufferBarHeight = 3.0f;

@interface ReplayerSlider : UISlider

- (CGRect)trackBlockRect;

@end

@implementation ReplayerSlider

/*** 自定义 UISlider 以便修改其进度条的高度 ***/
- (CGRect)trackRectForBounds:(CGRect)bounds {
    return CGRectMake(0, CGRectGetMidY(bounds), CGRectGetWidth(bounds), ReplayerSliderAndBufferBarHeight);
}

- (CGRect)trackBlockRect {
    return [self thumbRectForBounds:self.bounds trackRect:[self trackRectForBounds:self.bounds] value:self.value];
}

@end

@interface ReplayerTrackSlider ()

@property (nonatomic, strong) ReplayerSlider *trackSlider;

//! 缓冲进度条不用 UIProgressView 的原因
//! 如自定义上层 Slider 的高度， ProgressView 无法匹配 Slider 的准确位置，需要设置偏移量，容易出错
@property (nonatomic, strong) ReplayerSlider *bufferSlider;

@end

@implementation ReplayerTrackSlider

#pragma mark - init & layout

- (instancetype)init {
    if (self = [super init]) {
        
        [self addSubview:self.trackSlider];
        [self insertSubview:self.bufferSlider belowSubview:self.trackSlider];
        
        [self p_setupInnerLayout];
        
    }
    return self;
}

- (void)p_setupInnerLayout {
    
    [self.trackSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    [self.bufferSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
}
#pragma mark - Public

- (CGRect)trackBlockRect {
    return [self.trackSlider trackBlockRect];
}

- (UISlider *)playedTrack {
    return self.trackSlider;
}

#pragma mark set values

- (void)setPlayedValue:(float)value animated:(BOOL)animated {
    [self.trackSlider setValue:value animated:animated];
}

- (void)setBufferValue:(float)value animated:(BOOL)animated {
    [self.bufferSlider setValue:value animated:animated];
}

- (void)setPlayedTintColor:(UIColor *)playedTintColor {
    self.trackSlider.minimumTrackTintColor = playedTintColor;
}

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    self.bufferSlider.maximumTrackTintColor = trackTintColor;
}

- (void)setBufferedTintColor:(UIColor *)bufferedTintColor {
    self.bufferSlider.minimumTrackTintColor = bufferedTintColor;
}

#pragma mark set thumb image

- (void)setSliderBlock:(UIImage *)sliderBlock forState:(UIControlState)state {
    [self.trackSlider setThumbImage:sliderBlock forState:state];
}

#pragma mark - lazy load

- (ReplayerSlider *)trackSlider {
    if (!_trackSlider) {
        _trackSlider = [[ReplayerSlider alloc] init];
        _trackSlider.maximumTrackTintColor = [UIColor clearColor];
    }
    return _trackSlider;
}

- (ReplayerSlider *)bufferSlider {
    if (!_bufferSlider) {
        _bufferSlider = [[ReplayerSlider alloc] init];
        [_bufferSlider setThumbImage:[UIImage new] forState:UIControlStateNormal];
        [_bufferSlider setThumbImage:[UIImage new] forState:UIControlStateHighlighted];
        _bufferSlider.userInteractionEnabled = NO;
        _bufferSlider.minimumTrackTintColor = [UIColor lightGrayColor];
        _bufferSlider.maximumTrackTintColor = [UIColor blackColor];
    }
    return _bufferSlider;
}

@end
