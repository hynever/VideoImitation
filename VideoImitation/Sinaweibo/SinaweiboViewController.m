//
//  SinaweiboViewController.m
//  VideoImitation
//
//  Created by 黄勇 on 16/1/23.
//  Copyright © 2016年 xfz. All rights reserved.
//

#import "SinaweiboViewController.h"
#import <AVFoundation/AVFoundation.h> 
#import "SinaweiboVideoView.h"
#import "Masonry.h"

#define kWinWidth [UIScreen mainScreen].bounds.size.width

@interface SinaweiboViewController ()

@property(nonatomic,strong) SinaweiboVideoView *videoView;

@end

@implementation SinaweiboViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.edgesForExtendedLayout = UIRectEdgeNone;
    self.view.backgroundColor = [UIColor whiteColor];
    self.videoView.backgroundColor = [UIColor whiteColor];
}

#pragma mark _videoView
-(SinaweiboVideoView *)videoView
{
    if (!_videoView) {
        _videoView = [[SinaweiboVideoView alloc] init];
        [self.view addSubview:_videoView];
        [_videoView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self.view);
            make.height.equalTo(self.view.mas_width).multipliedBy(9.0f/16.0f);
        }];
    }
    return _videoView;
}

@end
