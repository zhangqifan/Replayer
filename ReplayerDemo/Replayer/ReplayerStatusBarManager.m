//
//  ReplayerStatusBarManager.m
//  ReplayerDemo
//
//  Created by qifan.zhang on 2017/6/29.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

#import "ReplayerStatusBarManager.h"
#import "UIWindow+GetCurrentViewController.h"

@implementation ReplayerStatusBarManager

#pragma mark - Singleton

+ (instancetype)sharedInstance{
    static ReplayerStatusBarManager *sharedInstance;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        sharedInstance = [[super allocWithZone:NULL] init];
        [[UIApplication sharedApplication].keyWindow addSubview:sharedInstance];
    });
    return sharedInstance;
}

+ (instancetype)allocWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

+ (id)copyWithZone:(struct _NSZone *)zone {
    return [self sharedInstance];
}

- (id)copy {
    return self;
}

#pragma mark - Setter

- (void)setStatusBarHidden:(BOOL)statusBarHidden {
    _statusBarHidden = statusBarHidden;
    UIWindow *window = [[UIApplication sharedApplication] keyWindow];
    [[window rep_getCurrentViewController] setNeedsStatusBarAppearanceUpdate];
}

@end
