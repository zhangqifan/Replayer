//
//  VideoListViewController.m
//  ReplayerDemo
//
//  Created by zhangqifan on 2017/6/26.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import "VideoListViewController.h"
#import "ReplayerViewController.h"
#import "Masonry.h"

static NSString * const videoCellIdentifier = @"videoCell";

@interface VideoListViewController () <UITableViewDelegate, UITableViewDataSource>

@property (nonatomic, strong) UITableView *videoTableView;
@property (nonatomic, copy) NSArray <NSString *> *videoTypeArray;

@end

@implementation VideoListViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // setup display
    [self.view addSubview:self.videoTableView];
    
    [self.videoTableView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(UIEdgeInsetsZero);
    }];
    
    self.title = @"Replayer 测试视频列表";
}

- (BOOL)shouldAutorotate {
    return NO;
}

#pragma mark - Setup Video List

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *videoCell = [tableView dequeueReusableCellWithIdentifier:videoCellIdentifier forIndexPath:indexPath];
    if (indexPath.section == 0) {
        videoCell.textLabel.text = [NSString stringWithFormat:@"HLS 测试视频 - %@",[self.videoTypeArray objectAtIndex:indexPath.row]];
    } else {
        videoCell.textLabel.text = [NSString stringWithFormat:@"视频控制样式 %ld （未完成）",indexPath.row+1];
    }
    
    videoCell.textLabel.font = [UIFont systemFontOfSize:14.0f];
    return videoCell;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    if (section == 0) {
        return self.videoTypeArray.count;
    } else {
        return 3;
    }
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return 2;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    [tableView deselectRowAtIndexPath:indexPath animated:YES];
    
    ReplayerViewController *replayerVC = [[ReplayerViewController alloc] init];
    replayerVC.videoSourceStr = @"https://devstreaming-cdn.apple.com/videos/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8";
    replayerVC.playingType = VideoPlayingTypeFullFeatures;
    [self.navigationController pushViewController:replayerVC animated:YES];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    UILabel *headerLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 0, 100, 20)];
    headerLabel.textColor = [UIColor darkGrayColor];
    headerLabel.font = [UIFont boldSystemFontOfSize:14.0f];
    section == 0 ? (headerLabel.text = @"   视频功能") : (headerLabel.text = @"   视频控制样式");
    return headerLabel;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 30.0f;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 0.00001;
}

#pragma mark - Getter

- (UITableView *)videoTableView {
    if (!_videoTableView) {
        _videoTableView = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStyleGrouped];
        _videoTableView.delegate = self;
        _videoTableView.dataSource = self;
        [_videoTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:videoCellIdentifier];
        _videoTableView.tableFooterView = [UIView new];
        _videoTableView.separatorInset = UIEdgeInsetsZero;
    }
    return _videoTableView;
}

- (NSArray<NSString *> *)videoTypeArray {
    if (!_videoTypeArray) {
        _videoTypeArray = @[@"基础播放/暂停功能",@"完整功能",@"播放结束后的模拟业务",@"播放本地视频",@"从某个时间点继续播放"];
    }
    return _videoTypeArray;
}

@end
