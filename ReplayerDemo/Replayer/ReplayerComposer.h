//
//  ReplayerComposer.h
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/5/31.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

// 宽
#define ScreenWidth         [[UIScreen mainScreen] bounds].size.width
// 高
#define ScreenHeight        [[UIScreen mainScreen] bounds].size.height
// RGBA
#define RGBA(r,g,b,a)       [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]
// Bundle assets
#define BUNDLE_PATH         [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"ReplayerResource.bundle"]
#define GetBundleAsset(_x_) [UIImage imageWithContentsOfFile:[BUNDLE_PATH stringByAppendingPathComponent:[NSString stringWithFormat:@"Contents/Resources/%@",_x_]]]

// Apple HTTP Live Streaming Test Video
#define StreamingURLDemo    @"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"

// 头文件
#import "Replayer.h"
#import "ReplayerTask.h"
#import "ReplayerPanel.h"
#import "ReplayerBrightness.h"
#import "ReplayerLoading.h"
#import "ReplayerPanelProtocol.h"
#import "ReplayerTrackSlider.h"
#import "Reachability.h"

#import "UIView+ReplayerPanelProtocol.h"
#import "UIWindow+GetCurrentViewController.h"

#import <Masonry.h>
#import <Toast/UIView+Toast.h>
#import <MMMaterialDesignSpinner/MMMaterialDesignSpinner.h>
