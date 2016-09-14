//
//  QLPlayer.h
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "Masonry.h"

@import MediaPlayer;
@import AVFoundation;

/**
 *  注意®:本人把属性公开到.h文件里，为了适配广大的开发者，不同的需求可以修改属性值，也可以直接修改源代码
 */
@interface QLPlayer : UIView

/**
 *  播放器player
 */
@property(nonatomic, retain)AVPlayer *player;

/**
 *  playerLayer,可以修改frame
 */
@property(nonatomic, retain)AVPlayerLayer *playerLayer;

/**
 *  底部操作工具栏
 */
@property(nonatomic, retain)UIView *bottomView;

@property(nonatomic, retain)UISlider *progressSlider;

@property(nonatomic, retain)UISlider *volumeSlider;

@property(nonatomic, copy)NSString *videoURLStr;
/**
 *  BOOL值判断当前的状态
 */
@property(nonatomic, assign)BOOL isFullScreen;

/**
 *  显示播放时间的UILabel
 */
@property(nonatomic, retain)UILabel *timeLabel;

/**
 *  显示全屏的按钮
 */
@property(nonatomic, retain)UIButton *fullScreenBtn;

/**
 *  播放暂停按钮
 */
@property(nonatomic, retain)UIButton *playOrPauseBtn;

/**
 *  关闭按钮
 */
@property(nonatomic, retain)UIButton *closeBtn;

/**
 *  playItem
 */
@property(nonatomic,retain)AVPlayerItem *currentItem;

/**
 *  初始化QLPlayer的方法
 *
 *  @param frame       frame
 *  @param videoURLStr URL字符串，包括网络的和本地的URL
 *  @return id类型，实际上就是QLPlayer的一个对象
 */
- (id)initWithFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr;

@end
