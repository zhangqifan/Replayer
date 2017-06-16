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

//#define StreamingURLDemo    @"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
#define StreamingURLDemo    @"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4"

#import "ReplayerTask.h"
#import "Replayer.h"
#import "ReplayerPanel.h"
#import "ReplayerBrightness.h"
#import "ReplayerLoading.h"
#import "ReplayerPanelProtocol.h"

#import "UIView+ReplayerPanelProtocol.h"
#import "UIWindow+GetCurrentViewController.h"
