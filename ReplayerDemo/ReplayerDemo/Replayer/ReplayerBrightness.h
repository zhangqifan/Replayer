//
//  ReplayerBrightness.h
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/6/1.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReplayerBrightness : UIView

/*** 将修改亮度实例创建为一个单例 ***/
+ (instancetype)sharedInstance;

/*** 状态栏显示/隐藏参数 ***/
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

@end
