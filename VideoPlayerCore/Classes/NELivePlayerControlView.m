//
//  NELivePlayerControlView.m
//  NELivePlayerDemo
//
//  Created by Netease on 2017/11/15.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "NELivePlayerControlView.h"
#import "UIView+NEPlayer.h"
#import "UIAlertController+Thunder.h"
#import "Masonry.h"
#import "VideoVolumeCell.h"
#import "MVideoVolume.h"
#define kPlayerBtnWidth (40)

@interface NELivePlayerControlView () {
    BOOL _isDraggingInternal;
}

@property(nonatomic, strong) UIControl *overlayControl; //控制层
@property(nonatomic, strong) UIActivityIndicatorView *bufferingIndicate; //缓冲动画
@property(nonatomic, strong) UILabel *bufferingReminder; //缓冲提示
@property(nonatomic, strong) UIView *topControlView; //顶部控制条
@property(nonatomic, strong) UIView *bottomControlView; //底部控制条
@property(nonatomic, strong) UIButton *playQuitBtn; //退出
@property(nonatomic, strong) UILabel *fileName; //文件名字
@property(nonatomic, strong) UILabel *currentTime;   //播放时间
@property(nonatomic, strong) UILabel *totalDuration; //文件时长
@property(nonatomic, strong) UISlider *videoProgress;//播放进度
@property(nonatomic, strong) UIButton *playBtn;  //播放/暂停按钮
@property(nonatomic, strong) UIButton *muteBtn;  //静音按钮
@property(nonatomic, strong) UIButton *scaleModeBtn; //显示模式按钮
@property(nonatomic, strong) UIButton *snapshotBtn;  //截图按钮
@property(nonatomic, strong) UIButton *tvBtn;  //投屏按钮
@property(nonatomic, strong) UIButton *fullBtn;  //全屏按钮

@property(nonatomic, strong) UIScrollView *xianluScrollView;  //线路列表

@property(nonatomic, strong) UILabel *xianluLabel;  //切换线路
@property(nonatomic, strong) UILabel *fenjiLabel; // 分集
@property(nonatomic, strong) NSArray *jxs;
@property(nonatomic, assign) int ct;
@property(nonatomic, assign) int has_jx;
@property(nonatomic, assign) int show_xl;

@property(nonatomic, strong) NSLayoutConstraint *totalDurationHMuteBtnConst;
@property(nonatomic, strong) NSLayoutConstraint *tvHXlConst;

@property(nonatomic, strong) UICollectionView *collectionView;
@property(nonatomic, strong) NSArray<MVideoVolume *> *volumeList;//选集数据

@end

    // 分集
@interface NELivePlayerControlView (Volume)<UICollectionViewDataSource, UICollectionViewDelegate>
- (void)configureCollectionView;
@end

@implementation NELivePlayerControlView

- (instancetype)initWithFrame:(CGRect)frame {
    
    if (self = [super initWithFrame:frame]) {
        [self setupSubviews];
    }
    return self;
}

- (void)setupSubviews {
    
    [self addSubview:self.mediaControl];
    [self.mediaControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(self);
    }];
    
    [_mediaControl addSubview:self.bufferingIndicate];
    [_mediaControl addSubview:self.bufferingReminder];
    [_bufferingIndicate mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(self.mediaControl);
        make.centerY.mas_equalTo(self.mediaControl).mas_offset(-16);
    }];
    [_bufferingReminder mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.mas_equalTo(_bufferingIndicate);
        make.top.mas_equalTo(_bufferingIndicate.mas_bottom).offset(32);
    }];
    
    [self addSubview:self.overlayControl];
    [self.overlayControl mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
    
    [_overlayControl addSubview:self.topControlView];
    [_topControlView addSubview:self.playQuitBtn];
    [_topControlView addSubview:self.fileName];
    [_topControlView addSubview:self.tvBtn];
        //    if (![self.isLineRoad isEqualToString:@""] || self.isLineRoad != nil) {
    [_topControlView addSubview:self.xianluLabel];
    [_topControlView addSubview:self.fenjiLabel];
        //    }
    [_topControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.top.mas_equalTo(self.overlayControl);
        make.height.mas_equalTo(40);
    }];
    [self setupTopControlSubViewConstraints];
    
    
    [_overlayControl addSubview:self.bottomControlView];
    [self.bottomControlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.trailing.bottom.mas_equalTo(self.overlayControl);
        make.height.mas_equalTo(40);
    }];
    
    [_bottomControlView addSubview:self.playBtn];
    [_bottomControlView addSubview:self.currentTime];
    [_bottomControlView addSubview:self.videoProgress];
    [_bottomControlView addSubview:self.totalDuration];
    [_bottomControlView addSubview:self.muteBtn];
    [_bottomControlView addSubview:self.snapshotBtn];
    [_bottomControlView addSubview:self.scaleModeBtn];
    [_bottomControlView addSubview:self.fullBtn];
    [self setupBottomControlSubViewConstraints];
    
    [_overlayControl addSubview:self.xianluScrollView];
    [self.xianluScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.topControlView.mas_bottom);
        make.trailing.mas_equalTo(0);
        make.width.mas_equalTo(100);
        make.height.mas_equalTo(200);
    }];
    self.xianluScrollView.bounces = NO;
    _show_xl = 0;
    
    [self configureCollectionView];
}

//判断字符串是否为空
- (BOOL)isBlankString:(NSString *)string {
    if (string == nil || string == NULL) {
        return YES;
    }
    if ([string isKindOfClass:[NSNull class]]) {
        return YES;
    }
    if ([[string stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]] length] == 0) {
        return YES;
    }
    return NO;
}

- (void)layoutSubviews {
    
    [super layoutSubviews];
    
    if (![self isBlankString:self.isLineRoad]) {
        self.xianluLabel.text = @"";
        self.xianluLabel.hidden = YES;
        self.fenjiLabel.hidden = YES;
    }else {
        self.xianluLabel.hidden = NO;
        self.fenjiLabel.hidden = NO;
        self.tvHXlConst.active = YES;
    }
    
        //    _mediaControl.frame = self.bounds;
        //    _bufferingIndicate.center = CGPointMake(_overlayControl.width / 2, (_overlayControl.height - 32) / 2);
        //    _bufferingReminder.top = _bufferingIndicate.bottom + 32.0;
        //    _bufferingReminder.centerX = _bufferingIndicate.centerX;
    
    
    [_scaleModeBtn setHidden:YES];
    [_snapshotBtn setHidden:YES];
    [_muteBtn setHidden:YES];
}

- (void)setupTopControlSubViewConstraints {
    [self.playQuitBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(8);
        make.width.mas_equalTo(kPlayerBtnWidth);
        make.height.mas_equalTo(self.topControlView);
    }];
    
    [self.fileName mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.playQuitBtn.mas_trailing).mas_offset(2);
        make.top.bottom.mas_equalTo(self.topControlView);
    }];
    
    [self.fileName setContentHuggingPriority:UILayoutPriorityDefaultLow-1 forAxis:UILayoutConstraintAxisHorizontal];
    
    [self.tvBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(30);
        make.bottom.top.mas_equalTo(self.topControlView);
        make.trailing.mas_equalTo(self.topControlView).mas_offset(0).priority(999);
        make.leading.mas_equalTo(self.fileName.mas_trailing).offset(8);
    }];
    
    [_xianluLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(60);
        make.top.bottom.mas_equalTo(self.topControlView);
    }];
    
    [_fenjiLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.xianluLabel.mas_trailing).mas_offset(0);
        make.width.mas_equalTo(0);
        make.top.bottom.trailing.mas_equalTo(self.topControlView);
    }];
    self.tvHXlConst = [NSLayoutConstraint constraintWithItem:self.tvBtn attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.xianluLabel attribute:NSLayoutAttributeLeading multiplier:1 constant:-4];
    self.tvHXlConst.priority = UILayoutPriorityRequired;
        //    self.tvHXlConst.active = NO;
    
    _fenjiLabel.text = @"选集";
    _xianluLabel.text = @"线路";
    
    UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapFenjiLabel:)];
    [self.fenjiLabel addGestureRecognizer:tapGestureRecognizer];
    self.fenjiLabel.userInteractionEnabled = YES;
}

- (void)setupBottomControlSubViewConstraints {
    [self.playBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_offset(8);
        make.width.mas_equalTo(kPlayerBtnWidth);
        make.top.bottom.mas_equalTo(self.bottomControlView);
    }];
    
    [_currentTime mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(_playBtn.mas_trailing).mas_offset(4);
        make.top.bottom.mas_equalTo(self.bottomControlView);
        make.width.mas_equalTo(kPlayerBtnWidth + 6);
    }];
    
    [_videoProgress mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(_currentTime.mas_trailing).mas_offset(4);
        make.top.bottom.mas_equalTo(self.bottomControlView);
    }];
    [self.videoProgress setContentHuggingPriority:UILayoutPriorityDefaultLow-1 forAxis:UILayoutConstraintAxisHorizontal];
    
    [_totalDuration mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(_videoProgress.mas_trailing).mas_offset(4);
        make.top.bottom.mas_equalTo(self.bottomControlView);
        make.width.mas_equalTo(_currentTime);
    }];
    
    [_fullBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.top.bottom.mas_equalTo(self.bottomControlView);
        make.width.mas_equalTo(self.playBtn);
        make.leading.mas_greaterThanOrEqualTo(_totalDuration.mas_trailing).mas_offset(4).priority(999);
    }];
    
    [self.scaleModeBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.fullBtn.mas_leading).mas_offset(-4);
        make.width.mas_equalTo(self.playBtn);
        make.top.bottom.mas_equalTo(self.bottomControlView);
    }];
    [self.snapshotBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.scaleModeBtn.mas_leading).mas_offset(-4);
        make.width.mas_equalTo(self.playBtn);
        make.top.bottom.mas_equalTo(self.bottomControlView);
    }];
    [self.muteBtn mas_makeConstraints:^(MASConstraintMaker *make) {
        make.trailing.mas_equalTo(self.snapshotBtn.mas_leading).mas_offset(-4);
        make.width.mas_equalTo(self.playBtn);
        make.top.bottom.mas_equalTo(self.bottomControlView);
    }];
    self.totalDurationHMuteBtnConst = [NSLayoutConstraint constraintWithItem:self.totalDuration attribute:NSLayoutAttributeTrailing relatedBy:NSLayoutRelationEqual toItem:self.muteBtn attribute:NSLayoutAttributeLeading multiplier:1 constant:-4];
    self.totalDurationHMuteBtnConst.priority = UILayoutPriorityRequired;
    [self.bottomControlView addConstraint:self.totalDurationHMuteBtnConst];
    self.totalDurationHMuteBtnConst.active = NO;
}

#pragma mark - Action

- (void)onClickMediaControlAction:(UIControl *)control {
    _overlayControl.hidden = NO;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(controlOverlayHide) object:nil];
    [self performSelector:@selector(controlOverlayHide) withObject:nil afterDelay:8];
}

- (void)onClickOverlayControlAction:(UIControl *)control {
    _overlayControl.hidden = YES;
    [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(controlOverlayHide) object:nil];
}

- (void)controlOverlayHide {
    _overlayControl.hidden = YES;
}

- (void)onClickBtnAction:(UIButton *)btn {
    
    if (btn == _playQuitBtn) {
        [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(controlOverlayHide) object:nil];
        
        if (_delegate && [_delegate respondsToSelector:@selector(controlViewOnClickQuit:)]) {
            [_delegate controlViewOnClickQuit:self];
        }
    } else if (btn == _playBtn) {
        _playBtn.selected = !_playBtn.isSelected;
        if (_delegate && [_delegate respondsToSelector:@selector(controlViewOnClickPlay:isPlay:)]) {
            [_delegate controlViewOnClickPlay:self isPlay:_playBtn.isSelected];
        }
    } else if (btn == _muteBtn) {
        _muteBtn.selected = !_muteBtn.isSelected;
        if (_delegate && [_delegate respondsToSelector:@selector(controlViewOnClickMute:isMute:)]) {
            [_delegate controlViewOnClickMute:self isMute:_muteBtn.isSelected];
        }
    } else if (btn == _scaleModeBtn) {
        _scaleModeBtn.selected = !_scaleModeBtn.isSelected;
        if (_delegate && [_delegate respondsToSelector:@selector(controlViewOnClickScale:isFill:)]) {
            [_delegate controlViewOnClickScale:self isFill:_scaleModeBtn.isSelected];
        }
    } else if (btn == _snapshotBtn) {
        if (_delegate && [_delegate respondsToSelector:@selector(controlViewOnClickSnap:)]) {
            [_delegate controlViewOnClickSnap:self];
        }
    } else if (btn == _fullBtn) {
        [_delegate clickFull:self];
    } else if (btn == _tvBtn) {
        [self searchTv];
    }
}

- (void)searchTv {
    [_delegate searchTv];
}

- (void)initJxWithJxs:(NSArray *)jxs ct:(int)ct {
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"初始化右上角解析线路菜单"] selector:_cmd];
    _jxs = jxs;
    _ct = ct;
    
    NSDictionary *jx = _jxs[_ct];
    _xianluLabel.text = jx[@"s_name"];
    
    UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(xlClick)];
    [_xianluLabel addGestureRecognizer:labelTapGestureRecognizer];
    _xianluLabel.userInteractionEnabled = YES;
    _has_jx = 1;
    for (UIView *view in self.xianluScrollView.subviews) {
        [view removeFromSuperview];
    }
    CGFloat top = 0;
    for (int i = 0; i < [_jxs count]; i++) {
        top = 30.5 * i;
        UILabel *label = [[UILabel alloc] init];
        label.frame = CGRectMake(0, top, 100, 30);
        
        NSDictionary *j = _jxs[i];
        label.text = j[@"s_name"];
        label.backgroundColor = [UIColor colorWithWhite:0.5 alpha:0.8];
        label.textColor = Color(@"#cccccc");
        label.textAlignment = NSTextAlignmentCenter;
        [_xianluScrollView addSubview:label];
        label.font = [UIFont systemFontOfSize:13];
        label.tag = i;
        UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(changeXl:)];
        [label addGestureRecognizer:labelTapGestureRecognizer];
        label.userInteractionEnabled = YES; // 可以理解为设置label可被点击
    }
    
    _xianluScrollView.contentSize = CGSizeMake(100, [_jxs count] * 30.5);
    
    [_xianluScrollView setHidden:YES];
    
        //    if (![self isBlankString:self.isLineRoad]) {
        //
        //        [_delegate getXl:];
        //    }else{
        //http://zuikzy.win7i.com/2018/07/10/FD2KhGi7xEzClPR9/playlist.m3u8
    
    
//    [_delegate getXl:jx[@"url"]];
        //    }
    
    
//    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(autoChangeLine:) name:@"autoChangeLine" object:nil];
}


- (void)xlClick {
    if (_has_jx == 0) return;
    if (_show_xl == 1) {
        [_xianluScrollView setHidden:YES];
        _show_xl = 0;
    } else {
        [_xianluScrollView setHidden:NO];
        _show_xl = 1;
    }
    self.collectionView.hidden = YES;
}

- (void)tapFenjiLabel:(id)sender {
    self.collectionView.hidden = !self.collectionView.hidden;
    [self.collectionView reloadData];
    self.selectedVolume = _selectedVolume;
    self.xianluScrollView.hidden = YES;
}

- (void)changeXl:(UITapGestureRecognizer *)recognizer {
    [_xianluScrollView setHidden:YES];
    _show_xl = 0;
    UILabel *label = (UILabel *) recognizer.view;
    int ct = (int) label.tag;
    if (ct == _ct) return;
    _ct = ct;
    NSDictionary *jx = _jxs[_ct];
    _xianluLabel.text = jx[@"s_name"];
//    [_delegate getXl:jx[@"url"]];
    if ([_delegate respondsToSelector:@selector(changeXianLuAtIndex:)]) {
        [_delegate changeXianLuAtIndex:_ct];
    }
}


- (void)onClickSeekAction:(UISlider *)slider forEvent:(UIEvent *)event{
    if (_isAllowSeek) {
        UITouch *touchEvent = [[event allTouches] anyObject];
        switch (touchEvent.phase) {
            case UITouchPhaseBegan:
                _isDraggingInternal = YES;
                break;
            case UITouchPhaseMoved: {
                NSTimeInterval currentPlayTime = slider.value;
                int mCurrentPostion = (int) currentPlayTime;
                _currentTime.text = [NSString stringWithFormat:@"%02d:%02d:%02d",
                                     (int) (mCurrentPostion / 3600),
                                     (int) (mCurrentPostion > 3600 ? (mCurrentPostion - (mCurrentPostion / 3600) * 3600) / 60 : mCurrentPostion / 60),
                                     (int) (mCurrentPostion % 60)];
                break;
            }
            case UITouchPhaseEnded:
                _isDraggingInternal = NO;
                break;
            default:
                break;
        }
       
    }
}

- (void)setFullDelay {
        //    _bufferingIndicate.center = CGPointMake(_overlayControl.width / 2, (_overlayControl.height - 32) / 2);
        //    _bufferingReminder.top = _bufferingIndicate.bottom + 32.0;
        //    _bufferingReminder.centerX = _bufferingIndicate.centerX;
    
    self.totalDurationHMuteBtnConst.active = YES;
    if ([self isBlankString:self.isLineRoad]) {
        [self.fenjiLabel mas_updateConstraints:^(MASConstraintMaker *make) {
            make.width.mas_equalTo(60);
        }];
    }
    [UIView animateWithDuration:0.25 animations:^{
        [_scaleModeBtn setHidden:NO];
        [_snapshotBtn setHidden:NO];
        [_muteBtn setHidden:NO];
        if ([self isBlankString:self.isLineRoad]) {
            self.tvHXlConst.active = YES;
        }
        [self layoutIfNeeded];
    }];
        //    _scaleModeBtn.frame = CGRectMake(_fullBtn.left - kPlayerBtnWidth, 0, kPlayerBtnWidth, _bottomControlView.height);
        //
        //    _snapshotBtn.frame = CGRectMake(_scaleModeBtn.left - kPlayerBtnWidth, 0, kPlayerBtnWidth, _bottomControlView.height);
        //
        //    _muteBtn.frame = CGRectMake(_snapshotBtn.left - kPlayerBtnWidth, 0, kPlayerBtnWidth, _bottomControlView.height);
    
        //    _totalDuration.frame = CGRectMake(_muteBtn.left - (_totalDuration.width + 4.0),
        //            0,
        //            _currentTime.width,
        //            _bottomControlView.height);
        //    _videoProgress.frame = CGRectMake(_currentTime.right + 4.0,
        //            0,
        //            _totalDuration.left - 4.0 - _currentTime.right - 4.0,
        //            _bottomControlView.height);
}

- (void)setFull {
    
    [self performSelector:@selector(setFullDelay) withObject:nil/*可传任意类型参数*/ afterDelay:0.5];
}

- (void)cancelFullDelay {
        //    _bufferingIndicate.center = CGPointMake(_overlayControl.width / 2, (_overlayControl.height - 32) / 2);
        //    _bufferingReminder.top = _bufferingIndicate.bottom + 32.0;
        //    _bufferingReminder.centerX = _bufferingIndicate.centerX;
    [_scaleModeBtn setHidden:YES];
    [_snapshotBtn setHidden:YES];
    [_muteBtn setHidden:YES];
    self.collectionView.hidden = YES;
    [self.fenjiLabel mas_updateConstraints:^(MASConstraintMaker *make) {
        make.width.mas_equalTo(0);
    }];
    self.totalDurationHMuteBtnConst.active = NO;
        //    self.tvHXlConst.active = NO;
    
        //    _totalDuration.frame = CGRectMake(_fullBtn.left - (_totalDuration.width + 4.0),
        //            0,
        //            _currentTime.width,
        //            _bottomControlView.height);
        //    _videoProgress.frame = CGRectMake(_currentTime.right + 4.0,
        //            0,
        //            _totalDuration.left - 4.0 - _currentTime.right - 4.0,
        //            _bottomControlView.height);
}

- (void)cancelFull {
    [self performSelector:@selector(cancelFullDelay) withObject:nil/*可传任意类型参数*/ afterDelay:0.5];
}

- (void)onClickSeekTouchUpInside:(UISlider *)slider {
    if (_isAllowSeek) {
        if (_delegate && [_delegate respondsToSelector:@selector(controlViewOnClickSeek:dstTime:)]) {
            [_delegate controlViewOnClickSeek:self dstTime:slider.value];
        }
    }
}

- (void)onClickSeekTouchUpOutside:(UISlider *)slider {
    if (_isAllowSeek) {
        _isDraggingInternal = NO;
    }
}

#pragma mark - Setter

- (BOOL)isDragging {
    return _isDraggingInternal;
}

- (void)setCurrentPos:(NSTimeInterval)currentPos {
    if (_isDraggingInternal) {
        return;
    }
    _currentPos = currentPos;
    NSInteger currPos = round(currentPos);
    _currentTime.text = [NSString stringWithFormat:@"%02d:%02d:%02d",
                         (int) (currPos / 3600),
                         (int) (currPos > 3600 ? (currPos - (currPos / 3600) * 3600) / 60 : currPos / 60),
                         (int) (currPos % 60)];
    _videoProgress.value = currentPos;
}

- (void)setDuration:(NSTimeInterval)duration {
    _duration = duration;
    
    if (duration > 0) {
        NSInteger mDuration = round(duration);
        _totalDuration.text = [NSString stringWithFormat:@"%02d:%02d:%02d",
                               (int) (mDuration / 3600),
                               (int) (mDuration > 3600 ? (mDuration - 3600 * (mDuration / 3600)) / 60 : mDuration / 60),
                               (int) (mDuration > 3600 ? ((mDuration - 3600 * (mDuration / 3600)) % 60) : (mDuration % 60))];
        _videoProgress.maximumValue = duration;
    } else {
        _videoProgress.value = 0.0;
        _totalDuration.text = @"--:--:--";
    }
}

- (void)setFileTitle:(NSString *)fileTitle {
    _fileTitle = fileTitle;
    if (fileTitle) {
        _fileName.text = fileTitle;
    }
}

- (void)changeXianLuTitleAtIndex:(NSInteger)index {
    NSDictionary *jx = _jxs[index];
    _xianluLabel.text = jx[@"s_name"];
}

//- (void)autoChangeLine:(NSNotification *)notification {
//    NSInteger index = [notification.object[@"index"] integerValue] % _jxs.count;
//    NSDictionary *jx = _jxs[index];
//    _xl.text = jx[@"s_name"];
//    [_delegate getXl:jx[@"url"]];
//}

- (void)setIsLineRoad:(NSString *)isLineRoad {
    _isLineRoad = isLineRoad;
    [self setNeedsLayout];
}

- (void)setIsPlaying:(BOOL)isPlaying {
    _isPlaying = isPlaying;
    _playBtn.selected = isPlaying;
}

- (void)setIsBuffing:(BOOL)isBuffing {
    _isBuffing = isBuffing;
    
    if (isBuffing) {
        _bufferingIndicate.hidden = NO;
        [_bufferingIndicate startAnimating];
        _bufferingReminder.hidden = NO;
        
    } else {
        _bufferingIndicate.hidden = YES;
        [_bufferingIndicate stopAnimating];
        _bufferingReminder.hidden = YES;
    }
}

- (void)reloadVolumeList:(NSArray *)volumeList {
    self.volumeList = volumeList;
    [self.collectionView reloadData];
}

#pragma mark - 控件属性

- (UIControl *)mediaControl {
    if (!_mediaControl) {
        _mediaControl = [[UIControl alloc] init];
        [_mediaControl addTarget:self action:@selector(onClickMediaControlAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _mediaControl;
}

- (UIControl *)overlayControl {
    if (!_overlayControl) {
        _overlayControl = [[UIControl alloc] init];
        [_overlayControl addTarget:self action:@selector(onClickOverlayControlAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _overlayControl;
}

- (UIActivityIndicatorView *)bufferingIndicate {
    if (!_bufferingIndicate) {
        _bufferingIndicate = [[UIActivityIndicatorView alloc] init];
        _bufferingIndicate.hidden = YES;
    }
    return _bufferingIndicate;
}

- (UILabel *)bufferingReminder {
    if (!_bufferingReminder) {
        _bufferingReminder = [[UILabel alloc] init];
        _bufferingReminder.text = @"缓冲中";
        _bufferingReminder.textAlignment = NSTextAlignmentCenter; //文字居中
        _bufferingReminder.textColor = [UIColor whiteColor];
        _bufferingReminder.hidden = YES;
        [_bufferingReminder sizeToFit];
    }
    return _bufferingReminder;
}

- (UIView *)topControlView {
    if (!_topControlView) {
        _topControlView = [[UIView alloc] init];
        _topControlView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ic_background_black"]];
        _topControlView.alpha = 0.8;
    }
    return _topControlView;
}

- (UIView *)bottomControlView {
    if (!_bottomControlView) {
        _bottomControlView = [[UIView alloc] init];
        _bottomControlView.backgroundColor = [UIColor colorWithPatternImage:[UIImage imageNamed:@"ic_background_black"]];
        _bottomControlView.alpha = 0.8;
    }
    return _bottomControlView;
}

- (UIButton *)playQuitBtn {
    if (!_playQuitBtn) {
        _playQuitBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playQuitBtn setImage:[UIImage imageNamed:@"btn_player_quit"] forState:UIControlStateNormal];
        [_playQuitBtn addTarget:self action:@selector(onClickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playQuitBtn;
}

- (UILabel *)fileName {
    if (!_fileName) {
        _fileName = [[UILabel alloc] init];
        _fileName.textAlignment = NSTextAlignmentLeft; //文字居中
        _fileName.textColor = [[UIColor alloc] initWithRed:191 / 255.0 green:191 / 255.0 blue:191 / 255.0 alpha:1];
        _fileName.font = [UIFont systemFontOfSize:13.0];
    }
    return _fileName;
}

- (UILabel *)xianluLabel {
    if (!_xianluLabel) {
        _xianluLabel = [[UILabel alloc] init];
        _xianluLabel.textAlignment = NSTextAlignmentCenter; //文字居中
        _xianluLabel.textColor = [[UIColor alloc] initWithRed:191 / 255.0 green:191 / 255.0 blue:191 / 255.0 alpha:1];
        _xianluLabel.font = [UIFont systemFontOfSize:13.0];
    }
    return _xianluLabel;
}

- (UILabel *)fenjiLabel {
    if (!_fenjiLabel) {
        _fenjiLabel = [[UILabel alloc] init];
        _fenjiLabel.textAlignment = NSTextAlignmentCenter; //文字居中
        _fenjiLabel.textColor = [[UIColor alloc] initWithRed:191 / 255.0 green:191 / 255.0 blue:191 / 255.0 alpha:1];
        _fenjiLabel.font = [UIFont systemFontOfSize:13.0];
    }
    return _fenjiLabel;
}

- (UIButton *)tvBtn {
    if (!_tvBtn) {
        _tvBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_tvBtn setImage:[UIImage imageNamed:@"icon_tv"] forState:UIControlStateNormal];
        [_tvBtn addTarget:self action:@selector(onClickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _tvBtn;
}

- (UIButton *)fullBtn {
    if (!_fullBtn) {
        _fullBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_fullBtn setImage:[UIImage imageNamed:@"icon_full"] forState:UIControlStateNormal];
        [_fullBtn addTarget:self action:@selector(onClickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _fullBtn;
}

- (UILabel *)currentTime {
    if (!_currentTime) {
        _currentTime = [[UILabel alloc] init];
        _currentTime.text = @"00:00:00"; //for test
        _currentTime.textAlignment = NSTextAlignmentCenter;
        _currentTime.textColor = [[UIColor alloc] initWithRed:191 / 255.0 green:191 / 255.0 blue:191 / 255.0 alpha:1];
        _currentTime.font = [UIFont systemFontOfSize:10.0];
        [_currentTime sizeToFit];
    }
    return _currentTime;
}

- (UILabel *)totalDuration {
    if (!_totalDuration) {
        _totalDuration = [[UILabel alloc] init];
        _totalDuration.text = @"--:--:--";
        _totalDuration.textAlignment = NSTextAlignmentCenter;
        _totalDuration.textColor = [[UIColor alloc] initWithRed:191 / 255.0 green:191 / 255.0 blue:191 / 255.0 alpha:1];
        _totalDuration.font = [UIFont systemFontOfSize:10.0];
        [_totalDuration sizeToFit];
    }
    return _totalDuration;
}

- (UISlider *)videoProgress {
    if (!_videoProgress) {
        _videoProgress = [[UISlider alloc] init];
        [_videoProgress setThumbImage:[UIImage imageNamed:@"btn_player_slider_thumb"] forState:UIControlStateNormal];
        [_videoProgress setMaximumTrackImage:[UIImage imageNamed:@"btn_player_slider_all"] forState:UIControlStateNormal];
        [_videoProgress setMinimumTrackImage:[UIImage imageNamed:@"btn_player_slider_played"] forState:UIControlStateNormal];
        [_videoProgress addTarget:self action:@selector(onClickSeekAction:forEvent:) forControlEvents:UIControlEventValueChanged];
        [_videoProgress addTarget:self action:@selector(onClickSeekTouchUpInside:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _videoProgress;
}

- (UIScrollView *)xianluScrollView {
    if (!_xianluScrollView) {
        _xianluScrollView = [[UIScrollView alloc] init];
    }
    return _xianluScrollView;
}

- (UIButton *)playBtn {
    if (!_playBtn) {
        _playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_playBtn setImage:[UIImage imageNamed:@"btn_player_pause"] forState:UIControlStateNormal];
        [_playBtn setImage:[UIImage imageNamed:@"btn_player_play"] forState:UIControlStateSelected];
        [_playBtn addTarget:self action:@selector(onClickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _playBtn;
}

- (UIButton *)muteBtn {
    if (!_muteBtn) {
        _muteBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_muteBtn setImage:[UIImage imageNamed:@"btn_player_mute02"] forState:UIControlStateNormal];
        [_muteBtn setImage:[UIImage imageNamed:@"btn_player_mute01"] forState:UIControlStateSelected];
        [_muteBtn addTarget:self action:@selector(onClickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _muteBtn;
}

- (UIButton *)scaleModeBtn {
    if (!_scaleModeBtn) {
        _scaleModeBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [_scaleModeBtn setImage:[UIImage imageNamed:@"btn_player_scale01"] forState:UIControlStateNormal];
        [_scaleModeBtn setImage:[UIImage imageNamed:@"btn_player_scale02"] forState:UIControlStateSelected];
        [_scaleModeBtn addTarget:self action:@selector(onClickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _scaleModeBtn;
}

- (UIButton *)snapshotBtn {
    if (!_snapshotBtn) {
        self.snapshotBtn = [UIButton buttonWithType:UIButtonTypeCustom];
        [self.snapshotBtn setImage:[UIImage imageNamed:@"btn_player_snap"] forState:UIControlStateNormal];
        [self.snapshotBtn addTarget:self action:@selector(onClickBtnAction:) forControlEvents:UIControlEventTouchUpInside];
    }
    return _snapshotBtn;
}

@end

@implementation NELivePlayerControlView (Volume)
- (void)setSelectedVolume:(NSInteger)selectedVolume {
    _selectedVolume = selectedVolume;
    if (selectedVolume < self.volumeList.count) {
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVolume inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionBottom];
        // 隐藏选集
    }
}

- (void)configureCollectionView {
    UICollectionViewFlowLayout *layout = [[UICollectionViewFlowLayout alloc] init];
    layout.itemSize = CGSizeMake(50, 50);
    layout.minimumLineSpacing = 10;
    layout.minimumInteritemSpacing = 10;
    layout.sectionInset = UIEdgeInsetsMake(10, 10, 0, 10);
    self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor colorWithWhite:0.3 alpha:0.5];
    
    [self.overlayControl addSubview:self.collectionView];
    [self.overlayControl bringSubviewToFront:self.collectionView];
    [self.collectionView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.topControlView.mas_bottom);
        make.trailing.mas_equalTo(0);
        make.width.mas_equalTo(self).multipliedBy(0.5);
        make.bottom.mas_equalTo(self.bottomControlView.mas_top);
    }];
    self.collectionView.hidden = YES;
    [self.collectionView registerClass:[OverlayVideoVolumeCell class] forCellWithReuseIdentifier:@"OverlayVideoVolumeCell"];
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.volumeList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    OverlayVideoVolumeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"OverlayVideoVolumeCell" forIndexPath:indexPath];
    cell.volumeText = [@(self.volumeList[indexPath.row].order) stringValue];
    cell.volume = self.volumeList[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.chooseVolume) {
        self.chooseVolume(indexPath, self.volumeList[indexPath.row]);
    }
    _selectedVolume = indexPath.row;
    [self tapFenjiLabel:nil];
}

@end
