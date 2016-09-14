//
//  TencentNewsViewController.m
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import "TencentNewsViewController.h"
#import "DetailViewController.h"
#import "VideoCell.h"

#import "SidModel.h"
#import "VideoModel.h"

#import "QLPlayer.h"
#import "AppDelegate.h"

@interface TencentNewsViewController ()<UITableViewDataSource,UITableViewDelegate,UIScrollViewDelegate>

@property(weak, nonatomic) IBOutlet UITableView *table;
@property(nonatomic, retain)VideoCell *currentCell;
@end

@implementation TencentNewsViewController

{
    NSMutableArray *dataSource;
    QLPlayer *qlPlayer;
    NSIndexPath *currentIndexPath;
    BOOL isSmallScreen;
    
}

- (instancetype)init
{
    if (self = [super init]) {
        dataSource = [NSMutableArray array];
        isSmallScreen = NO;
    }
    return self;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    //
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(videoDidFinished:) name:AVPlayerItemDidPlayToEndTimeNotification object:nil];
    //全屏
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(fullScreenBtnClick:) name:@"fullScreenBtnClickNotice" object:nil];
    
    //关闭
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(closeTheVideo:) name:@"closeTheVideo" object:nil];
    
    [self.table registerNib:[UINib nibWithNibName:@"VideoCell" bundle:nil] forCellReuseIdentifier:@"VideoCell"];
    
    //刷新
    [self addMJRefresh];
    [self.table.mj_header beginRefreshing];
}
- (void)addMJRefresh
{
    __unsafe_unretained UITableView *tableView = self.table;
   //下拉刷新
    tableView.mj_header = [MJRefreshNormalHeader headerWithRefreshingBlock:^{
       
        [[DataManage shareManager] getSidArrayWithURLString:@"http://c.m.163.com/nc/video/home/0-10.html" succecc:^(NSArray *sidArray, NSArray *videoArray) {
            dataSource = [NSMutableArray arrayWithArray:videoArray];
            dispatch_async(dispatch_get_main_queue(), ^{
                if (currentIndexPath.row > dataSource.count) {
                    [self releaseQLPlayer];
                }
                [tableView reloadData];
                [tableView.mj_header endRefreshing];
            });
            
        } failed:^(NSError *error) {
            
        }];
    }];
   
    //下拉自动切换透明度（在导航栏下面自动隐藏）
    tableView.mj_header.automaticallyChangeAlpha = YES;
    //上拉刷新
    tableView.mj_footer = [MJRefreshBackNormalFooter footerWithRefreshingBlock:^{
        NSString *URLString = [NSString stringWithFormat:@"http://c.m.163.com/nc/video/home/%ld-10.html",dataSource.count - dataSource.count%10];
        [[DataManage shareManager] getSidArrayWithURLString:URLString succecc:^(NSArray *sidArray, NSArray *videoArray) {
            [dataSource addObjectsFromArray:videoArray];
            dispatch_async(dispatch_get_main_queue(), ^{
                [tableView reloadData];
                [tableView.mj_footer endRefreshing];
            });
        } failed:^(NSError *error) {
            
        }];
    }];
}
- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillDisappear:YES];
    //屏幕旋转
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onDeviceOrientationChange) name:UIDeviceOrientationDidChangeNotification object:nil];
}

- (void)viewDidAppear:(BOOL)animated
{
    [super viewDidAppear:YES];
//    [self performSelector:@selector(loadData) withObject:nil afterDelay:1.0];
}

- (void)loadData
{            //******************** 数据源有问题 ******************//
    dataSource =[NSMutableArray arrayWithArray:[AppDelegate shareAppDelegate].videoArray];
    [self.table reloadData];
}



#pragma mark dataSourceDelegate
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return 1;
}
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return dataSource.count;
}
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *identifier = @"VideoCell";
    VideoCell *cell = (VideoCell *)[tableView dequeueReusableCellWithIdentifier:identifier];
    VideoModel *model = dataSource[indexPath.row];
    cell.model = model;
    [cell.playBtn addTarget:self action:@selector(startPlayVideo:) forControlEvents:UIControlEventTouchUpInside];
    cell.playBtn.tag = indexPath.row;
    
    cell.backgroundIV.backgroundColor = [UIColor redColor];
    
    
    if (qlPlayer && qlPlayer.superview) {
        if (indexPath == currentIndexPath) {
            [cell.playBtn.superview sendSubviewToBack:cell.playBtn];
        }
        else{
            [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
        }
        
        //屏幕内所有显示视图的indexPath
        NSArray *indexPaths = [tableView indexPathsForVisibleRows];
        
        if (![indexPaths containsObject:currentIndexPath]) {
            if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:qlPlayer]) {
                qlPlayer.hidden = NO;
            }
            else{
                qlPlayer.hidden = YES;
                [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
            }
        }
        else{
            if ([cell.backgroundIV.subviews containsObject:qlPlayer]) {
                [cell.backgroundIV addSubview:qlPlayer];
                
                [qlPlayer.player play];
                qlPlayer.playOrPauseBtn.selected = NO;
                qlPlayer.hidden = NO;
            }
        }
        
    }
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 274;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    VideoModel *model = [dataSource objectAtIndex:indexPath.row];
    
    DetailViewController *detailVC = [[DetailViewController alloc] init];
    detailVC.URLString = model.m3u8_url;
    detailVC.title = model.title;
    [self.navigationController pushViewController:detailVC animated:YES];
}

#pragma mark 开始播放
- (void)startPlayVideo:(UIButton *)sender
{
    currentIndexPath = [NSIndexPath indexPathForRow:sender.tag inSection:0];
    NSLog(@"currentIndexPath.row = %ld",currentIndexPath.row);
    
    self.currentCell = (VideoCell *)sender.superview.superview;
    VideoModel *model = [dataSource objectAtIndex:sender.tag];
    isSmallScreen = NO;
    
    if (qlPlayer) {
        [qlPlayer removeFromSuperview];
        [qlPlayer setVideoURLStr:model.mp4_url];
        [qlPlayer.player play];
    }
    else{
        qlPlayer = [[QLPlayer alloc] initWithFrame:self.currentCell.backgroundIV.frame videoURLStr:model.mp4_url];
        [qlPlayer .player play];
    }
    [self.currentCell.backgroundIV addSubview:qlPlayer];
    [self.currentCell.playBtn.superview sendSubviewToBack:self.currentCell.playBtn];
    [self.currentCell.backgroundIV bringSubviewToFront:qlPlayer];
    [self.table reloadData];
}
#pragma mark 通知
#pragma mark 全屏按钮点击
- (void)fullScreenBtnClick:(NSNotification *)notic
{
    //取到按钮
    UIButton *fullScreenBtn = (UIButton *)[notic object];
    if (fullScreenBtn.isSelected) {
        [self toFullScreenWithInterfaceOrientation:UIInterfaceOrientationLandscapeLeft];
    }
    else{
        if (isSmallScreen) {
            [self toSmallScreen];
        }
        else{
            [self toCell];
        }
    }
}
-  (void)toCell
{
    VideoCell *currentCell = self.currentCell;
    [qlPlayer removeFromSuperview];
    [UIView animateWithDuration:0.5f animations:^{
        qlPlayer.transform = CGAffineTransformIdentity;
        qlPlayer.frame = currentCell.backgroundIV.bounds;
        qlPlayer.playerLayer.frame =  qlPlayer.bounds;
        [currentCell.backgroundIV addSubview:qlPlayer];
        [currentCell.backgroundIV bringSubviewToFront:qlPlayer];
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
        isSmallScreen = NO;
        qlPlayer.fullScreenBtn.selected = NO;
        
    }];
}
//小屏
- (void)toSmallScreen
{
    [qlPlayer removeFromSuperview];
    [UIView animateWithDuration:0.5f animations:^{
        qlPlayer.transform = CGAffineTransformIdentity;
        qlPlayer.frame = CGRectMake(kScreenWidth/2, kScreenHeight-kTabBarHeight-(kScreenWidth/2)*0.75, kScreenWidth/2, kScreenWidth/2*0.75);
        qlPlayer.playerLayer.frame = qlPlayer.frame;
        //小屏的qlPlayer放在window层上
        [[UIApplication sharedApplication].keyWindow addSubview:qlPlayer];
        //重新约束
        [qlPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.left.equalTo(qlPlayer).with.offset(0);
            make.right.equalTo(qlPlayer).with.offset(0);
            make.bottom.equalTo(qlPlayer).with.offset(0);
            make.height.mas_equalTo(40);
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
        isSmallScreen = YES;
        [[UIApplication sharedApplication].keyWindow bringSubviewToFront:qlPlayer];
    }];
}
//全屏
- (void)toFullScreenWithInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
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
    //重新约束
    [qlPlayer.bottomView mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.height.mas_equalTo(40);
        make.top.mas_equalTo(kScreenWidth-40);
        make.width.mas_equalTo(kScreenHeight);
    }];
    [qlPlayer.closeBtn mas_remakeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(qlPlayer).with.offset((-kScreenHeight/2));
        make.height.mas_equalTo(30);
        make.width.mas_equalTo(30);
        make.top.equalTo(qlPlayer).with.offset(5);
        
    }];
    
    [[UIApplication sharedApplication].keyWindow addSubview:qlPlayer];
    
    qlPlayer.isFullScreen = YES;
    qlPlayer.fullScreenBtn.selected = YES;
    [qlPlayer bringSubviewToFront:qlPlayer.bottomView];
}
- (void)videoDidFinished:(NSNotification *)notic
{
    //取到当前cell位置
    VideoCell *currentCell = [self.table cellForRowAtIndexPath:[NSIndexPath indexPathForRow:currentIndexPath.row inSection:0]];
    //显示出按钮
    [currentCell.playBtn.superview bringSubviewToFront:currentCell.playBtn];
    //移除播放层
    [qlPlayer removeFromSuperview];
}

- (void)closeTheVideo:(NSNotification *)notic
{
    VideoCell *cell = [self.table cellForRowAtIndexPath:currentIndexPath];
    [cell.playBtn.superview bringSubviewToFront:cell.playBtn];
    [self releaseQLPlayer];
}
- (void)onDeviceOrientationChange
{
    if (qlPlayer == nil||qlPlayer.superview == nil) {
        return;
    }
    UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
    UIInterfaceOrientation interfaceOrientation = (UIInterfaceOrientation)orientation;
    switch (interfaceOrientation) {
        case UIInterfaceOrientationPortraitUpsideDown://倒置
            
            break;
        case UIInterfaceOrientationPortrait://正
            if (qlPlayer.isFullScreen) {
                if (isSmallScreen) {
                    [self toSmallScreen];
                }
                else{
                    [self toCell];
                }
            }
            break;
        case UIInterfaceOrientationLandscapeLeft://左
            if (qlPlayer.isFullScreen == NO) {
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
            break;
        case UIInterfaceOrientationLandscapeRight://右
            if (qlPlayer.isFullScreen == NO) {
                [self toFullScreenWithInterfaceOrientation:interfaceOrientation];
            }
        default:
            break;
    }
}
- (void)releaseQLPlayer
{
    [qlPlayer.player.currentItem cancelPendingSeeks];
    [qlPlayer.player.currentItem.asset cancelLoading];
    
    [qlPlayer.player pause];
    [qlPlayer removeFromSuperview];
    [qlPlayer.player replaceCurrentItemWithPlayerItem:nil];
    [qlPlayer.playerLayer removeFromSuperlayer];
    qlPlayer = nil;
    
    qlPlayer.player = nil;
    qlPlayer.currentItem = nil;
    qlPlayer.playOrPauseBtn = nil;
    qlPlayer.playerLayer = nil;
    currentIndexPath = nil;
}

#pragma mark 滚动
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    if (scrollView == self.table) {
        if (qlPlayer == nil) {
            return;
        }
        if (qlPlayer.superview) {
            CGRect rectInTableView = [self.table rectForRowAtIndexPath:currentIndexPath];
            CGRect rectInSuperView = [self.table convertRect:rectInTableView toView:self.table];
            
            NSLog(@"rectInTableView = %@",NSStringFromCGRect(rectInTableView));
            NSLog(@"rectInSuperview = %@",NSStringFromCGRect(rectInSuperView));
            if (rectInSuperView.origin.y < -self.currentCell.backgroundIV.frame.size.height||rectInSuperView.origin.y>kScreenHeight - kNavbarHeight - kTabBarHeight) {
                if ([[UIApplication sharedApplication].keyWindow.subviews containsObject:qlPlayer]) {
                    isSmallScreen = YES;
                }
                else{
                    [self toSmallScreen];
                }
            }
            else{
                if ([self.currentCell.backgroundIV.subviews containsObject:qlPlayer]) {
                    
                }
                else{
                    [self toSmallScreen];
                }
            }

        }
    }
}
- (void)dealloc
{
    NSLog(@"%@ dealloc",[self class]);
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}
@end

