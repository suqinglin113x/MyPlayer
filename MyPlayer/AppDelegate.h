//
//  AppDelegate.h
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface AppDelegate : UIResponder <UIApplicationDelegate>

@property (strong, nonatomic) UIWindow *window;

@property(nonatomic, strong)NSArray *sidArray;
@property(nonatomic, strong)NSArray *videoArray;

+ (AppDelegate *)shareAppDelegate;
@end

