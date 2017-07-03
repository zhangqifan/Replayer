//
//  ReplayerStatusBarManager.h
//  ReplayerDemo
//
//  Created by qifan.zhang on 2017/6/29.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReplayerStatusBarManager : UIView

+ (instancetype)sharedInstance;

/*** 状态栏显示/隐藏参数 ***/
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

@end
