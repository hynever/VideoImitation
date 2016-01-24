//
//  SinaweiboVideoView.m
//  VideoImitation
//
//  Created by 黄勇 on 16/1/23.
//  Copyright © 2016年 xfz. All rights reserved.
//

#import "SinaweiboVideoView.h"
#import <AVFoundation/AVFoundation.h>
#import "AFNetworking.h"
#import "Masonry.h"

static NSString * const STATUS_KEYPATH = @"status";

static const NSString *PlayerItemStatusContext;

@interface SinaweiboVideoView ()

@property(nonatomic,strong) UIView *topBar;

@property(nonatomic,strong) UIView *bottomBar;

@property(nonatomic,strong) UIButton *dismissBtn;

@property(nonatomic,strong) UIButton *moreBtn;

@property(nonatomic,strong) UIButton *playbackBtn;

@property(nonatomic,strong) UISlider *timeSlider;

@property(nonatomic,strong) UILabel *currentTimeLabel;

@property(nonatomic,strong) UILabel *totalTimeLabel;

@property(nonatomic,strong) UIImageView *playImageView;

@property(nonatomic,strong) AVPlayer *player;

@property(nonatomic,strong) AVPlayerLayer *playerLayer;

@property(nonatomic,strong) AVPlayerItem *playerItem;

@property(nonatomic,assign) BOOL isPlaying;

@property(nonatomic,assign) BOOL isFullScreen;

@end

@implementation SinaweiboVideoView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        _isFullScreen = NO;
        _isPlaying = NO;
        [self setupControl];
        [self setupEvent];
        [self preparePlay];
        [self bringSubviewToFront:self.playImageView];
    }
    return self;
}

-(void)setupControl
{
    _bottomBar = [UIView new];
    [self addSubview:_bottomBar];
    [_bottomBar mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.right.bottom.equalTo(self);
        make.height.equalTo(@(80));
    }];
    
    self.playbackBtn = [[UIButton alloc] init];
    [self.playbackBtn setImage:[UIImage imageNamed:@"videoplayer_icon_stop"] forState:UIControlStateNormal];
    [self.playbackBtn setImage:[UIImage imageNamed:@"videoplayer_icon_play"] forState:UIControlStateSelected];
    [_bottomBar addSubview:self.playbackBtn];
    [self.playbackBtn addTarget:self action:@selector(playbackAction) forControlEvents:UIControlEventTouchUpInside];
    [self.playbackBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(_bottomBar).offset(20);
        make.bottom.equalTo(_bottomBar).offset(-20);
        make.size.mas_equalTo(CGSizeMake(30, 30));
    }];
    
    self.totalTimeLabel = [[UILabel alloc] init];
    self.totalTimeLabel.font = [UIFont systemFontOfSize:12];
    self.totalTimeLabel.textColor = [UIColor whiteColor];
    [_bottomBar addSubview:self.totalTimeLabel];
    [self.totalTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(_bottomBar).offset(20);
        make.bottom.equalTo(self.playbackBtn);
    }];
    
    self.currentTimeLabel = [[UILabel alloc] init];
    self.currentTimeLabel.font = self.totalTimeLabel.font;
    self.currentTimeLabel.textColor = self.totalTimeLabel.textColor;
    [_bottomBar addSubview:self.currentTimeLabel];
    [self.currentTimeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.playbackBtn.mas_right).offset(30);
        make.bottom.equalTo(self.playbackBtn);
    }];
    
    self.timeSlider = [[UISlider alloc] init];
    self.timeSlider.maximumValue = 1.0f;
    self.timeSlider.minimumValue = 0.0f;
    [_bottomBar addSubview:self.timeSlider];
    [self.timeSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.currentTimeLabel.mas_right).offset(10);
        make.bottom.equalTo(self.currentTimeLabel);
        make.right.equalTo(self.totalTimeLabel.mas_left).offset(-20);
    }];
}

-(void)setupEvent
{
    UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(selfTapedAction)];
    [self addGestureRecognizer:tapGesture];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(viedoEndPlayAction) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
}

-(void)preparePlay
{
    //        NSString *filePath = [[NSBundle mainBundle] pathForResource:@"hubblecast" ofType:@"m4v"];
    //        NSURL *fileUrl = [[NSURL alloc] initFileURLWithPath:filePath];
    //        NSURL *m3u8Url = [NSURL URLWithString:@"https://devimages.apple.com.edgekey.net/streaming/examples/bipbop_16x9/bipbop_16x9_variant.m3u8"];
    
    NSURL *mp4Url = [NSURL URLWithString:@"http://7xqenu.com1.z0.glb.clouddn.com/VID_20151128_094717.mp4"];
    AVAsset *asset = [AVAsset assetWithURL:mp4Url];
    
    self.playerItem = [AVPlayerItem playerItemWithAsset:asset automaticallyLoadedAssetKeys:@[@"tracks",@"duration",@"commonMetadata"]];
    [self.playerItem addObserver:self forKeyPath:STATUS_KEYPATH options:0 context:&PlayerItemStatusContext];
    self.player = [AVPlayer playerWithPlayerItem:self.playerItem];
    
    self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
    self.playerLayer.backgroundColor = [UIColor blackColor].CGColor;
    
    [self.layer addSublayer:self.playerLayer];

    self.currentTimeLabel.text = @"00:00";
    self.totalTimeLabel.text = [self formatTimeWithCMTime:self.playerItem.duration];
}

#pragma mark - event方法
-(void)selfTapedAction
{
    //先设置是否在播放
    if (!self.isPlaying) {
        self.player.volume = 1.0f;
        [self playVideo];
    }else{
        //设置声音为0
        self.player.volume = 0.0f;
    }
    
    //设置大小
    if (!self.isFullScreen) {
        self.playImageView.hidden = YES;
        [self setFullScreenSize];
        self.topBar.hidden = NO;
        self.bottomBar.hidden = NO;
        self.player.volume = 1.0f;
    }else{
        [self setNormalSize];
        self.topBar.hidden = YES;
        self.bottomBar.hidden = YES;
    }
}

-(void)playVideo
{
    [self.player play];
    [self.player seekToTime:kCMTimeZero];
    self.isPlaying =YES;
}

-(void)closeAction
{
    //停止播放
    [self.player setRate:0.0f];
    [self.player seekToTime:kCMTimeZero];
    [self setNormalSize];
    self.topBar.hidden = YES;
    self.bottomBar.hidden = YES;
    self.playImageView.hidden = NO;
    self.isPlaying = NO;
}

-(void)moreAction
{
    NSLog(@"more");
}

-(void)playbackAction
{
    NSLog(@"playbackAction");
    if (self.isPlaying) {
        [self.player pause];
        self.isPlaying = NO;
        self.playImageView.hidden = NO;
        self.playbackBtn.selected = YES;
    }else{
        [self.player play];
        self.isPlaying = YES;
        self.playbackBtn.selected = NO;
        self.playImageView.hidden = YES;
    }
}

-(void)viedoEndPlayAction
{
    [self.player seekToTime:kCMTimeZero];
    self.isPlaying = NO;
    
    //展示三个按钮（重播、分享、更多视频）
    
}

-(void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context{
    if (context == &PlayerItemStatusContext) {
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.playerItem removeObserver:self forKeyPath:STATUS_KEYPATH];
            if (self.playerItem.status == AVPlayerItemStatusReadyToPlay) {
                
            }
        });
    }
}

-(void)setNormalSize
{
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.left.right.top.equalTo(self.superview);
        make.height.equalTo(self.superview.mas_width).multipliedBy(9.0f/16.0f);
    }];
    [UIView animateWithDuration:0.5f animations:^{
        [self layoutIfNeeded];
    }];
    self.isFullScreen = NO;
}

-(void)setFullScreenSize
{
    [self mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self.superview);
    }];
    [UIView animateWithDuration:0.5f animations:^{
        [self layoutIfNeeded];
    }];
    self.isFullScreen = YES;
}

-(NSString *)formatTimeWithCMTime:(CMTime)time
{
    NSInteger totalSeconds = CMTimeGetSeconds(time);
    NSInteger minutes = totalSeconds%60;
    NSInteger seconds = totalSeconds/60;
    return [NSString stringWithFormat:@"%02ld:%02ld", (long) minutes, (long) seconds];
}


#pragma mark _topBar
-(UIView *)topBar
{
    if (!_topBar) {
        _topBar = [UIView new];
        _topBar.userInteractionEnabled = YES;
        [self addSubview:_topBar];
        [_topBar mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.right.top.equalTo(self);
            make.height.equalTo(@80);
        }];
        
        self.dismissBtn = [[UIButton alloc] init];
        [self.dismissBtn addTarget:self action:@selector(closeAction) forControlEvents:UIControlEventTouchUpInside];
        [self.dismissBtn setImage:[UIImage imageNamed:@"feed_video_icon_close"] forState:UIControlStateNormal];
        [self.dismissBtn setImage:[UIImage imageNamed:@"feed_video_icon_close_highlighted"] forState:UIControlStateHighlighted];
        [_topBar addSubview:self.dismissBtn];
        [self.dismissBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.left.top.equalTo(_topBar).offset(20);
            make.size.mas_equalTo(CGSizeMake(30, 30));
        }];
        
        self.moreBtn = [[UIButton alloc] init];
        [self.moreBtn addTarget:self action:@selector(moreAction) forControlEvents:UIControlEventTouchUpInside];
        [self.moreBtn setImage:[UIImage imageNamed:@"userinfo_apps_more"] forState:UIControlStateNormal];
        [_topBar addSubview:self.moreBtn];
        [self.moreBtn mas_makeConstraints:^(MASConstraintMaker *make) {
            make.top.equalTo(_topBar).offset(20);
            make.right.equalTo(_topBar).offset(-20);
            make.size.mas_equalTo(CGSizeMake(30, 30));
        }];
    }
    return _topBar;
}


#pragma mark _playBtn
-(UIImageView *)playImageView
{
    if (!_playImageView) {
        _playImageView = [UIImageView new];
        _playImageView.layer.masksToBounds = YES;
        _playImageView.layer.cornerRadius = 25;
        _playImageView.layer.borderWidth = 2;
        _playImageView.layer.borderColor = [UIColor whiteColor].CGColor;
        _playImageView.contentMode = UIViewContentModeCenter;
        _playImageView.backgroundColor = [[UIColor whiteColor] colorWithAlphaComponent:0.5];
        _playImageView.image = [UIImage imageNamed:@"videoplayer_icon_play"];
        [self addSubview:_playImageView];
        [_playImageView mas_makeConstraints:^(MASConstraintMaker *make) {
            make.center.equalTo(self);
            make.size.mas_equalTo(CGSizeMake(50, 50));
        }];
    }
    return _playImageView;
}

-(void)layoutSubviews
{
    [super layoutSubviews];
    if (self.playerLayer) {
        self.playerLayer.frame = self.bounds;
    }
}


@end
