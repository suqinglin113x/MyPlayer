//
//  QLPlayer.m
//  MyPlayer
//
//  Created by SU on 16/8/23.
//  Copyright © 2016年 SU. All rights reserved.
//

#import "QLPlayer.h"

#define QLVideoSrcName(file) [@"WMPlayer.bundle" stringByAppendingPathComponent:file]
#define QLVideoFrameworkSrcName(file) [@"Frameworks/WMPlayer.framework/WMPlayer.bundle" stringByAppendingPathComponent:file]

static void *PlayViewStatusObservationContext = &PlayViewStatusObservationContext;
static void *PlayViewCMTimeValue = &PlayViewCMTimeValue;

@interface QLPlayer ()

@property(nonatomic, assign)CGPoint firstPoint;
@property(nonatomic, assign)CGPoint secondPoint;
@property(nonatomic, retain)NSTimer *durationTimer;
@property(nonatomic, retain)NSTimer *autoDismissTimer; //底部tool自动消失
@property(nonatomic, retain)NSDateFormatter *dateFormatter;

@end


@implementation QLPlayer
{
    UISlider *systemSlider;
}

- (AVPlayerItem *)getPlayItemWithURLString:(NSString *)urlString
{
    if ([urlString containsString:@"http"]) {// 网址类型
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithURL:[NSURL URLWithString:[urlString stringByAddingPercentEscapesUsingEncoding:NSUTF8StringEncoding]]];
        return playerItem;
    }
    else{ //本地类型
        AVAsset *movieAsset = [[AVURLAsset alloc] initWithURL:[NSURL URLWithString:urlString] options:nil];
        AVPlayerItem *playerItem = [AVPlayerItem playerItemWithAsset:movieAsset];
        return playerItem;
    }
}

- (instancetype)initWithFrame:(CGRect)frame videoURLStr:(NSString *)videoURLStr
{
    self = [super init];
    if (self) {
        self.frame = frame;
        self.backgroundColor = [UIColor blackColor];
        self.currentItem = [self getPlayItemWithURLString:videoURLStr];
        //AVPlayer
        self.player = [AVPlayer playerWithPlayerItem:self.currentItem];
        //AVPlayerLayer
        self.playerLayer = [AVPlayerLayer playerLayerWithPlayer:self.player];
        self.playerLayer.frame = self.layer.frame;
        [self.layer addSublayer:_playerLayer];
        
        //搭建播放窗口
        [self createPlayWindowUI];
       
        
        //添加手势单击和双击
        UITapGestureRecognizer *singleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleSingleTap)];
        singleTap.numberOfTapsRequired = 1;//单击
        [self addGestureRecognizer:singleTap];
        
        UITapGestureRecognizer *doubleTap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(handleDoubleTap)];
        doubleTap.numberOfTapsRequired = 2;//双击
        [self addGestureRecognizer:doubleTap];
        
        [self.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
        
        [self initTimer];
    }
    return self;
}

/**
 *  播放窗口
 */
- (void)createPlayWindowUI
{
    //bottomView
    self.bottomView = [[UIView alloc] init];
    [self addSubview:self.bottomView];
    [self.bottomView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self).with.offset(0);
        make.right.equalTo(self).with.offset(0);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self).with.offset(0);
    }];
    
    [self setAutoresizesSubviews:NO];
    
    //playOrPauseBtn
    self.playOrPauseBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playOrPauseBtn.showsTouchWhenHighlighted = YES;//button按下时会发光的属性
    [self.playOrPauseBtn addTarget:self action:@selector(playOrPause:) forControlEvents:UIControlEventTouchUpInside];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:QLVideoSrcName(@"pause")]?:[UIImage imageNamed:QLVideoFrameworkSrcName(@"pause")] forState:UIControlStateNormal];
    [self.playOrPauseBtn setImage:[UIImage imageNamed:QLVideoSrcName(@"play")]?:[UIImage imageNamed:QLVideoFrameworkSrcName(@"play")] forState:UIControlStateSelected];
    [self.bottomView addSubview:self.playOrPauseBtn];
    [self.playOrPauseBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(0);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.height.mas_equalTo(40);
        make.width.mas_equalTo(40);
    }];
    
    //音量view
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    [self addSubview:volumeView];
    [volumeView sizeToFit];
    
    //系统音量slider
    systemSlider = [[UISlider alloc] init];
    systemSlider.backgroundColor = [UIColor clearColor];
    for (UIControl *view in volumeView.subviews) {
        if ([view.superclass isSubclassOfClass:[UISlider class]]) {
            systemSlider = (UISlider *)view;
        }
    }
    systemSlider.autoresizesSubviews = NO;
    systemSlider.autoresizingMask = UIViewAutoresizingNone;
    [self addSubview:systemSlider];
    systemSlider.hidden = YES; //
    
    //自定义音量slider
    self.volumeSlider = [[UISlider alloc] initWithFrame:CGRectMake(0, 0, 0, 0)];
    self.volumeSlider.tag = 1000;
    self.volumeSlider.hidden = YES;
    self.volumeSlider.minimumValue = systemSlider.minimumValue;
    self.volumeSlider.maximumValue = systemSlider.maximumValue;
    self.volumeSlider.value = systemSlider.value;
    [self.volumeSlider addTarget:self action:@selector(updateSystemVolumeValue:) forControlEvents:UIControlEventValueChanged];
    [self addSubview:self.volumeSlider];
    
    //播放进度slider
    self.progressSlider = [[UISlider alloc] init];
    self.progressSlider.minimumValue = 0.0;
    self.progressSlider.value = 0.0;//初始值为0
    [self.progressSlider setThumbImage:[UIImage imageNamed:@"dot"] forState:UIControlStateNormal];
    self.progressSlider.minimumTrackTintColor = [UIColor greenColor];
    [self.progressSlider addTarget:self action:@selector(updateProgress:) forControlEvents:UIControlEventValueChanged];
    [self.bottomView addSubview:self.progressSlider];
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(40);
        make.bottom.equalTo(self.bottomView).with.offset(0);
    }];
    
    //fullScreenBtn
    self.fullScreenBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.fullScreenBtn.showsTouchWhenHighlighted = YES;
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"fullscreen"] forState:UIControlStateNormal];
    [self.fullScreenBtn setImage:[UIImage imageNamed:@"nonfullscreen"] forState:UIControlStateSelected];
    [self.fullScreenBtn addTarget:self action:@selector(fullScreenAction:) forControlEvents:UIControlEventTouchUpInside];
    [self.bottomView addSubview:self.fullScreenBtn];
    [self.fullScreenBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.right.equalTo(self.bottomView).with.offset(0);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.width.mas_equalTo(40);
        make.height.mas_equalTo(40);
    }];
    
    //timeLabel
    self.timeLabel = [[UILabel alloc] init];
    self.timeLabel.textAlignment = NSTextAlignmentCenter;
    self.timeLabel.textColor = [UIColor whiteColor];
    self.timeLabel.backgroundColor = [UIColor clearColor];
    self.timeLabel.font = [UIFont boldSystemFontOfSize:11];
    [self.bottomView addSubview:self.timeLabel];
    [self.timeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(45);
        make.bottom.equalTo(self.bottomView).with.offset(0);
        make.right.equalTo(self.bottomView).with.offset(-45);
        make.height.mas_equalTo(20);
    }];
    
    //closeBtn
    self.closeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.closeBtn.showsTouchWhenHighlighted = YES;
    [self.closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateNormal];
    [self.closeBtn setImage:[UIImage imageNamed:@"close"] forState:UIControlStateSelected];
    [self.closeBtn addTarget:self action:@selector(closeTheViedo:) forControlEvents:UIControlEventTouchUpInside];
    self.closeBtn.layer.cornerRadius = 10.f;
    [self addSubview:self.closeBtn];
    [self.closeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.bottomView).with.offset(5);
        make.top.equalTo(self).with.offset(5);
        make.width.mas_equalTo(30);
        make.height.mas_equalTo(30);
    }];
}

- (void)layoutSubviews
{
    [super layoutSubviews];
    self.playerLayer.frame = self.bounds;
}

#pragma mark 播放or暂停
- (void)playOrPause:(UIButton *)sender
{
    if (self.durationTimer == nil) {
        self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(finishedPlay:) userInfo:nil repeats:YES];
        [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
    }
    sender.selected = !sender.selected;
    if (self.player.rate != 1.f) { //暂停->播放
        if ([self currentTime] == [self durationTime]) { //当前时间等于片长时间，播放完成，
            [self setCurrentTime:0]; //回到初始状态
        }
        [self.player play];
    }
    else{//播放->暂停
        [self.player pause];
    }
}
/**
 *  设置当前时长
 *
 *  @param time <#time description#>
 */
- (void)setCurrentTime:(double)time
{
    [self.player seekToTime:CMTimeMakeWithSeconds(time, 1)];
}
/**
 *  当前时长
 */
- (double)currentTime
{
    return CMTimeGetSeconds([self.player currentTime]);
}
/**
 *  片长
 */
- (double)durationTime
{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        return CMTimeGetSeconds(playerItem.asset.duration);
    }
    else{
        return 0.f;
    }
}
#pragma mark 系统slider赋值
- (void)updateSystemVolumeValue:(UISlider *)slider
{
    systemSlider.value = slider.value;
}

#pragma mark updateProgress
- (void)updateProgress:(UISlider *)slider
{
    [self.player seekToTime:CMTimeMakeWithSeconds(slider.value, 1)];
}

#pragma mark fullScreenAction
- (void)fullScreenAction:(UIButton *)sender
{
    sender.selected = !sender.selected;
    //用通知的形式把点击全屏的时间发送到app的任何地方，方便处理其他逻辑
    [[NSNotificationCenter defaultCenter] postNotificationName:@"fullScreenBtnClickNotice" object:sender];
}

#pragma mark closeTheViedo
- (void)closeTheViedo:(UIButton *)sender
{
    [self.player pause];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"closeTheVideo" object:sender];
}

#pragma mark handleSingleTap
- (void)handleSingleTap
{
    [UIView animateWithDuration:0.5 animations:^{
        if (self.bottomView.alpha == 0.0) {
            self.bottomView.alpha = 1.0;
            self.closeBtn.alpha = 1.0;
        }
        else{
            self.bottomView.alpha = 0.0;
            self.closeBtn.alpha = 0.0;
        }
    }];
}

#pragma mark handleDoubleTap
- (void)handleDoubleTap
{
    self.playOrPauseBtn.selected = !self.playOrPauseBtn.selected;
    if (self.player.rate != 1.f) {//暂停状态->开始播放
        if ([self currentTime] == [self durationTime])
            [self setCurrentTime:0.0f];
        [self.player play];
    }
    else{ //正在播放->暂停播放
        [self.player pause];
    }
}

#pragma mark
- (void)setVideoURLStr:(NSString *)videoURLStr
{
    _videoURLStr = videoURLStr;
    if (self.currentItem) {
        [[NSNotificationCenter defaultCenter] removeObserver:self name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
        [self.currentItem removeObserver:self forKeyPath:@"status"];
    }
    
    self.currentItem = [self getPlayItemWithURLString:videoURLStr];
    [self.currentItem addObserver:self forKeyPath:@"status" options:NSKeyValueObservingOptionInitial|NSKeyValueObservingOptionNew context:PlayViewStatusObservationContext];
    [self.player replaceCurrentItemWithPlayerItem:self.currentItem];
    
    //视频播放结束通知
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moviePlayDidEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_currentItem];
    
}

- (void)moviePlayDidEnd:(NSNotification *)notification
{
    __weak typeof(self) weakSelf = self;
    [self.player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        [weakSelf.progressSlider setValue:0.0 animated:YES];//
        weakSelf.playOrPauseBtn.selected = NO;
    }];
}

//
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == PlayViewStatusObservationContext) {
        AVPlayerStatus status = [[change objectForKey:NSKeyValueChangeNewKey] integerValue];
        switch (status) {
            case AVPlayerStatusUnknown:
                
                break;
              case AVPlayerStatusReadyToPlay:
                //
                if (CMTimeGetSeconds(self.player.currentItem.duration)) {
                    self.progressSlider.maximumValue = CMTimeGetSeconds(self.player.currentItem.duration);
                }
                [self  initTimer];
                if (self.durationTimer == nil) {
                    self.durationTimer = [NSTimer scheduledTimerWithTimeInterval:0.2 target:self selector:@selector(finishedPlay:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop] addTimer:self.durationTimer forMode:NSDefaultRunLoopMode];
                }
                
                //5s 后bottomView 自动消失
                if (self.autoDismissTimer == nil) {
                    self.autoDismissTimer = [NSTimer scheduledTimerWithTimeInterval:5.0 target:self selector:@selector(autoDismissBottomView:) userInfo:nil repeats:YES];
                    [[NSRunLoop currentRunLoop] addTimer:self.autoDismissTimer forMode:NSDefaultRunLoopMode];
                }
        
                break;
                case AVPlayerStatusFailed:
                break;
            default:
                break;
        }
    }
}

- (void)finishedPlay:(NSTimer *)timer
{
    if ([self currentTime] == [self durationTime] && self.player.rate == 0.f) {
        self.playOrPauseBtn.selected = YES;
        //播放完成发送通知
        [[NSNotificationCenter defaultCenter] postNotificationName:@"finishedPlay" object:self.durationTimer];
        [self.durationTimer invalidate];
        self.durationTimer = nil;
    }
}

- (void)autoDismissBottomView:(NSTimer *)timer
{
    if (self.player.rate == .0f && [self currentTime] != [self durationTime]) { //暂停状态
        
    }
    else if (self.player.rate == 1.0f){//播放状态
        if (self.bottomView.alpha == 1.0) {
            [UIView animateWithDuration:0.5 animations:^{
                self.bottomView.alpha = 0.5;
                self.closeBtn.alpha = 0.0;
            }];
        }
    }
}
#pragma mark 定时器
- (void)initTimer
{
    double interval = .1f;
    CMTime playerDuration = [self playerItemDuration];
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        CGFloat width = CGRectGetWidth([self.progressSlider bounds]);
        interval = 0.5*duration/width;
    }
    
    __weak typeof(self) weakSelf = self;
    [self.player addPeriodicTimeObserverForInterval:CMTimeMakeWithSeconds(interval,NSEC_PER_SEC) queue:NULL usingBlock:^(CMTime time) {
        [weakSelf syncScrubber];
    }];
}

- (void)syncScrubber
{
   CMTime playerDuration = [self playerItemDuration];
    if (CMTIME_IS_INVALID(playerDuration)) {
        self.progressSlider.minimumValue = 0.0;
        return;
    }
    
    double duration = CMTimeGetSeconds(playerDuration);
    if (isfinite(duration)) {
        float minValue = [self.progressSlider minimumValue];
        float maxValue = [self.progressSlider maximumValue];
        double time = CMTimeGetSeconds([self.player currentTime]);
        _timeLabel.text = [NSString stringWithFormat:@"%@/%@",[self convertTime:time],[self convertTime:duration]];
        [self.progressSlider setValue:(maxValue - minValue) * time / duration + minValue];
                           
    }
}

/**
 *  返回时间
 */
- (NSString *)convertTime:(CGFloat)seconds
{
    if (_dateFormatter == nil) {
        _dateFormatter = [[NSDateFormatter alloc] init];
    }
    if (seconds/3600 >=1) {
        _dateFormatter.dateFormat = @"HH:mm:ss";
    }
    else{
        _dateFormatter.dateFormat = @"mm:ss";
    }
    NSDate *date = [NSDate dateWithTimeIntervalSince1970:seconds];
    NSString *newTime = [_dateFormatter stringFromDate:date];
    return newTime;
}
/**
 *  返回当前播放位置的cmtime
 */
- (CMTime)playerItemDuration
{
    AVPlayerItem *playerItem = self.player.currentItem;
    if (playerItem.status == AVPlayerItemStatusReadyToPlay) {
        return [playerItem duration];
    }
    return kCMTimeInvalid;
}

#pragma mark 手势滑动改变音量的处理
/**
 *  对音量的处理
 */
- (void)touchesBegan:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in event.allTouches) {
        self.firstPoint = [touch locationInView:self];
    }
    UISlider *slider = (UISlider *)[self viewWithTag:1000];//取到volumeSlider
    slider.value = systemSlider.value;
}

- (void)touchesMoved:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    for (UITouch *touch in event.allTouches) {
        self.secondPoint = [touch locationInView:self];
    }
    UISlider *slider = (UISlider *)[self viewWithTag:1000];
    systemSlider.value += (self.secondPoint.y - self.firstPoint.y) / 500;
    slider.value = systemSlider.value;
    self.firstPoint = self.secondPoint;
}

- (void)touchesEnded:(NSSet<UITouch *> *)touches withEvent:(UIEvent *)event
{
    //手指离开，请零
    self.firstPoint = self.secondPoint = CGPointZero;
}

- (void)dealloc
{
    [self.player pause];
    self.autoDismissTimer = nil;
    self.durationTimer = nil;
    self.player = nil;
    [self.currentItem removeObserver:self forKeyPath:@"status"];
}
@end
