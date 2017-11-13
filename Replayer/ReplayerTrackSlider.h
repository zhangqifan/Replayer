//
//  ReplayerTrackSlider.h
//
//  Created by zhangqifan on 2017/6/1.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface ReplayerTrackSlider : UIControl

/*!
    @attention
    左侧部分进度条默认着色为系统 tintColor
    右侧部分进度条默认着色为 [UIColor blackColor]
 */

/*** 已经播放的视频进度条颜色 ***/
@property (nullable, nonatomic, strong) UIColor *playedTintColor;

/*** 已经缓冲的进度条颜色 ***/
@property (nullable, nonatomic, strong) UIColor *bufferedTintColor;

/*** 未缓冲的进度条颜色 ***/
@property (nullable, nonatomic, strong) UIColor *trackTintColor;

/*** 视频播放进度条（只读） ***/
@property (nonatomic, strong, readonly) UISlider *playedTrack;

/**
 设置播放进度条数值

 @param value 播放进度
 @param animated animated
 @discussion value between 0.0 ~ 1.0
 */
- (void)setPlayedValue:(float)value animated:(BOOL)animated;

/**
 设置缓冲进度数值

 @param value 缓冲数值
 @param animated animated
 @discussion value between 0.0 ~ 1.0
 */
- (void)setBufferValue:(float)value animated:(BOOL)animated;

/**
 设置滑杆上的图片

 @param sliderBlock 自定义的滑竿图片
 @param state 选择状态
 */
- (void)setSliderBlock:(UIImage *)sliderBlock forState:(UIControlState)state;

/**
 返回滑块的位置

 @return CGRect
 */
- (CGRect)trackBlockRect;

@end

NS_ASSUME_NONNULL_END
