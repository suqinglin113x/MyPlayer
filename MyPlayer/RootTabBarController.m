//
//  RootTabBarController.m
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import "RootTabBarController.h"
#import "TencentNewsViewController.h"
#import "SinaNewsViewController.h"
#import "NetEaseViewController.h"
#import "BaseNavigationController.h"

@interface RootTabBarController ()
{
    NSTimer *timer;
    NSInteger count;
}
@end

@implementation RootTabBarController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    TencentNewsViewController *tencentVC = [[TencentNewsViewController alloc] init];
    tencentVC.title = @"腾讯";
    
    BaseNavigationController *tencentNav = [[BaseNavigationController alloc] initWithRootViewController:tencentVC];
    tencentNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"腾讯" image:[UIImage imageNamed:@"found"] selectedImage:[UIImage imageNamed:@"found_s"]];
    
    SinaNewsViewController *sinaVC = [[SinaNewsViewController alloc] init];
    sinaVC.title = @"新浪";
    
    BaseNavigationController *sinaNav = [[BaseNavigationController alloc] initWithRootViewController:sinaVC];
    sinaNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"新浪" image:[UIImage imageNamed:@"message"] selectedImage:[UIImage imageNamed:@"message_s"]];
    
    NetEaseViewController *netEaseVC = [[NetEaseViewController alloc] init];
    netEaseVC.title = @"网易";
    
    BaseNavigationController *netEaseNav = [[BaseNavigationController alloc] initWithRootViewController:netEaseVC];
    netEaseNav.tabBarItem = [[UITabBarItem alloc] initWithTitle:@"网易" image:[UIImage imageNamed:@"share"] selectedImage:[UIImage imageNamed:@"share_s"]];
    
    self.viewControllers = @[tencentNav,sinaNav,netEaseNav];
    self.tabBar.tintColor = [UIColor redColor];
    
}

@end
