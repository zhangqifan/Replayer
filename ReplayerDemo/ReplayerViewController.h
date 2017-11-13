//
//  ReplayerViewController.h
//  ReplayerDemo
//
//  Created by zhangqifan on 2017/6/26.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import <UIKit/UIKit.h>

typedef NS_ENUM(NSUInteger, VideoPlayingType) {
    VideoPlayingTypeBase,
    VideoPlayingTypeFullFeatures,
    VideoPlayingTypeBeforeReplay,
    VideoPlayingTypeLocalVideo,
    VideoPlayingTypeResume
};

@interface ReplayerViewController : UIViewController

@property (nonatomic, strong) NSString *videoSourceStr;

@property (nonatomic, assign) VideoPlayingType playingType;

@end
