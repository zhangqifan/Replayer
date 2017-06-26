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

#define StreamingURLDemo    @"https://devstreaming-cdn.apple.com/videos/streaming/examples/img_bipbop_adv_example_ts/master.m3u8"
//#define StreamingURLDemo    @"http://baobab.wdjcdn.com/1456459181808howtoloseweight_x264.mp4"
//#define StreamingURLDemo    @"https://video.youxiangtv.com/%E3%80%8A%E5%8F%98%E5%BD%A2%E9%87%91%E5%88%9A5%EF%BC%9A%E6%9C%80%E5%90%8E%E7%9A%84%E9%AA%91%E5%A3%AB%E3%80%8B%E2%80%9C%E8%8B%B1%E9%9B%84%E9%9B%86%E7%BB%93%E2%80%9D%E7%89%88%E4%B8%AD%E6%96%87%E9%A2%84%E5%91%8A_m3u8_240P_480P_20170622.m3u8"

#import "ReplayerTask.h"
#import "Replayer.h"
#import "ReplayerPanel.h"
#import "ReplayerBrightness.h"
#import "ReplayerLoading.h"
#import "ReplayerPanelProtocol.h"

#import "UIView+ReplayerPanelProtocol.h"
#import "UIWindow+GetCurrentViewController.h"

#import <Masonry.h>
