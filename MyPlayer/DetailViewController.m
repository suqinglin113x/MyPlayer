//
//  DetailViewController.m
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import "DetailViewController.h"

@interface DetailViewController ()
{
    QLPlayer *qlPlayer;
    CGRect playerFrame;
}
@end

@implementation DetailViewController

- (instancetype)init
{
    if (self = [super init]) {
        //注册全屏通知
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullScreenBtnClick:) name:@"fullScreenBtnClickNotice" object:nil];
    }
    return self;
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //旋转通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientation) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)fullScreenBtnClick:(NSNotification *)notice
{
    UIButton *fullScrrenBtn = (UIButton *)notice.object;
    if (fullScrrenBtn.isSelected) {
        [self toFullScreenWithOrientation:UIInterfaceOrientationLandscapeLeft];
    }
    else{
        [self toNormal];
    }
}

- (void)toFullScreenWithOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    [[UIApplication sharedApplication]setStatusBarHidden:YES];
    [qlPlayer removeFromSuperview];
    qlPlayer.transform = CGAffineTransformIdentity;
    if (interfaceOrientation == UIInterfaceOrientationLandscapeLeft) {
        qlPlayer.transform = CGAffineTransformMakeRotation(-M_PI_2);
    }
    else if (interfaceOrientation == UIInterfaceOrientationLandscapeRight){
        qlPlayer.transform = CGAffineTransformMakeRotation(M_PI_2);
    }
    qlPlayer.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
    qlPlayer.playerLayer.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
    
    [qlPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(self.view.frame.size.width-40);
        make.width.mas_equalTo(self.view.frame.size.height);
    }];
    
    [qlPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(qlPlayer).with.offset((-self.view.frame.size.height/2));
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(qlPlayer).with.offset(5);
        
    }];
    [[UIApplication sharedApplication].keyWindow addSubview:qlPlayer];
    qlPlayer.isFullScreen = YES;
    qlPlayer.fullScreenBtn.selected = YES;
    [qlPlayer bringSubviewToFront:qlPlayer.bottomView];
    
}

- (void)toNormal
{
    [qlPlayer removeFromSuperview];
    [UIView animateWithDuration:0.5f animations:^{
        qlPlayer.transform = CGAffineTransformIdentity;
        qlPlayer.frame = CGRectMake(playerFrame.origin.x, playerFrame.origin.y, playerFrame.size.width, playerFrame.size.height);
        qlPlayer.playerLayer.frame = qlPlayer.bounds;
        [self.view addSubview:qlPlayer];
        [qlPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(qlPlayer).with.offset(0);
            make.right.equalTo(qlPlayer).with.offset(0);
            make.height.mas_equalTo(40);
            make.bottom.equalTo(qlPlayer).with.offset(0);
        }];
        [qlPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(qlPlayer).with.offset(5);
            make.height.mas_equalTo(30);
            make.width.mas_equalTo(30);
            make.top.equalTo(qlPlayer).with.offset(5);
        }];
        
    }completion:^(BOOL finished) {
        qlPlayer.isFullScreen = NO;
        qlPlayer.fullScreenBtn.selected = NO;
        [[UIApplication sharedApplication] setStatusBarHidden:NO];
    }];
    
}

/**
 *  屏幕旋转
 */
- (void)onDeviceOrientation
{
    if (qlPlayer == nil||qlPlayer.superview == nil) {
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation
    ;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationLandscapeLeft:
            if (qlPlayer.isFullScreen == NO) {
                [self toFullScreenWithOrientation:interfaceOrientation];
            }
            break;
        case UIInterfaceOrientationLandscapeRight:
            if (qlPlayer.isFullScreen == NO) {
                [self toFullScreenWithOrientation:interfaceOrientation];
            }
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            break;
        case UIInterfaceOrientationPortrait:
            if (qlPlayer.isFullScreen) {
                [self toNormal];
            }
            break;
        default:
            break;
    }
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    playerFrame = CGRectMake(0, 64, kScreenWidth, kScreenWidth*3/4);
    qlPlayer = [[QLPlayer alloc] initWithFrame:playerFrame videoURLStr:self.URLString];
    qlPlayer.closeBtn.hidden = YES;
    [self.view addSubview:qlPlayer];
    [qlPlayer.player play];
    

}

- (void)dealloc
{
    [self releaseQLPlayer];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

- (void)releaseQLPlayer
{
    [qlPlayer.player.currentItem cancelPendingSeeks];
    [qlPlayer.player.currentItem.asset cancelLoading];
    
    [qlPlayer.player pause];
    [qlPlayer removeFromSuperview];
    [qlPlayer.playerLayer removeFromSuperlayer];
    [qlPlayer.player replaceCurrentItemWithPlayerItem:nil];
    qlPlayer = nil;
    qlPlayer.player = nil;
    qlPlayer.currentItem = nil;
    
    qlPlayer.playOrPauseBtn = nil;
    qlPlayer.playerLayer = nil;
}
@end
