//
//  UIWindow+GetCurrentViewController.m
//
//  Created by zhangqifan on 2017/6/6.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import "UIWindow+GetCurrentViewController.h"

@implementation UIWindow (GetCurrentViewController)

- (UIViewController *)rep_getCurrentViewController {
    UIViewController *topViewController = [self rootViewController];
    while (true) {
        if (topViewController.presentedViewController) {
            topViewController = topViewController.presentedViewController;
        } else if ([topViewController isKindOfClass:[UINavigationController class]] && [(UINavigationController*)topViewController topViewController]) {
            topViewController = [(UINavigationController *)topViewController topViewController];
        } else if ([topViewController isKindOfClass:[UITabBarController class]]) {
            UITabBarController *tab = (UITabBarController *)topViewController;
            topViewController = tab.selectedViewController;
        } else {
            break;
        }
    }
    return topViewController;
}

@end
