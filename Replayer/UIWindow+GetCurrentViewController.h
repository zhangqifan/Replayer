//
//  UIWindow+GetCurrentViewController.h
//
//  Created by zhangqifan on 2017/6/6.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface UIWindow (GetCurrentViewController)

/**
 获取当前视图的 vc

 @return ViewController
 */
- (UIViewController *)rep_getCurrentViewController;

@end
