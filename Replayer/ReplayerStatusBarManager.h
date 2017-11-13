//
//  ReplayerStatusBarManager.h
//
//  Created by zhangqifan on 2017/6/29.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ReplayerStatusBarManager : UIView

+ (instancetype)sharedInstance;

/*** 状态栏显示/隐藏参数 ***/
@property (nonatomic, assign, getter=isStatusBarHidden) BOOL statusBarHidden;

@end
