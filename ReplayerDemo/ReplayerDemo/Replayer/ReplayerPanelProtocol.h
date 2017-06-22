//
//  ReplayerPanelProtocol.h
//  PlayerInCaffe
//
//  Created by qifan.zhang on 2017/5/31.
//  Copyright © 2017年 qifan.zhang. All rights reserved.
//

/*
    @discussion  控制视频的代理方法
 */
@protocol ReplayerPanelProtocol <NSObject>

@optional

///////////////////////// 控制板上按钮事件 /////////////////////////

/*** 视频播放 或 暂停 ***/
- (void)replayerPanel:(UIView *)replayerPanel doPlayAction:(id)sender;

/*** 视频按钮触发全屏 ***/
- (void)replayerPanel:(UIView *)replayerPanel forceToFullScreenAction:(id)sender;

/*** 返回按钮触发事件 ***/
- (void)replayerPanel:(UIView *)replayerPanel goBackAction:(id)sender;

/*** 重播事件 ***/
- (void)replayerPanel:(UIView *)replayerPanel replayAction:(id)sender;

/*** 锁定屏幕操作 ***/
- (void)replayerPanel:(UIView *)replayerPanel forceToLockAction:(id)sender;

/*** 加载或缓冲失败 ***/
- (void)replayerPanel:(UIView *)replayerPanel failToLoadOrBuffer:(id)sender;

///////////////////////// 进度条事件 /////////////////////////

/*** 进度条开始触摸 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarTouchBegan:(id)sender;

/*** 进度条点击前进 或 后退 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarTapAction:(CGFloat)tapLocation;

/*** 进度条拖动事件 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarValueChanged:(id)sender;

/*** 进度条触摸结束 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarTouchEnded:(id)sender;

/*** 拖动后释放进度条 ***/
- (void)replayerPanel:(UIView *)replayerPanel progressBarTouchUpInside:(id)sender;

///////////////////////// 控制板显示周期 /////////////////////////

/*** 控制板将要显示 ***/
- (void)replayerPanelWillComeOut:(UIView *)replayerPanel;

/*** 控制板将要隐藏 ***/
- (void)replayerPanelWillDisappear:(UIView *)replayerPanel;

///////////////////////// 网络状态监测 /////////////////////////

/*** 允许使用流量事件 ***/
- (void)replayerPanelPassToUseCellular:(UIView *)replayerPanel;

@end
