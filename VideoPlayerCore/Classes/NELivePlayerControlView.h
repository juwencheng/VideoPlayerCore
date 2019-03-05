//
//  NELivePlayerControlView.h
//  NELivePlayerDemo
//
//  Created by Netease on 2017/11/15.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MVideoVolume;
@protocol NELivePlayerControlViewProtocol;

@interface NELivePlayerControlView : UIView

-(void)initJxWithJxs:(NSArray *)jxs ct:(int)ct;
-(void)setFull;
-(void)cancelFull;

- (void)reloadVolumeList:(NSArray *)volumeList;
- (void)changeXianLuTitleAtIndex:(NSInteger)index;

@property (nonatomic, assign, readonly) BOOL isDragging; //正在拖拽

@property (nonatomic, assign) NSTimeInterval currentPos; //当前播放时间

@property (nonatomic, assign) NSTimeInterval duration; //视频时长

@property (nonatomic, assign) NSString *fileTitle; //视频标题

@property (nonatomic, assign) BOOL isPlaying; //正在播放

@property (nonatomic, assign) BOOL isBuffing; //正在缓冲

@property (nonatomic, assign) BOOL isAllowSeek; //是否允许seek

@property (nonatomic, assign) NSString *isLineRoad; //是否可选线路

@property (nonatomic, weak) id<NELivePlayerControlViewProtocol> delegate;
@property (nonatomic, strong) UIControl *mediaControl; //媒体覆盖层

@property (nonatomic, copy) void (^chooseVolume)(NSIndexPath *indexPath, MVideoVolume *volumeData);
@property (nonatomic, assign) NSInteger selectedVolume;

@end

@protocol NELivePlayerControlViewProtocol <NSObject>

- (void)controlViewOnClickQuit:(NELivePlayerControlView *)controlView;
- (void)controlViewOnClickPlay:(NELivePlayerControlView *)controlView isPlay:(BOOL)isPlay;
- (void)controlViewOnClickSeek:(NELivePlayerControlView *)controlView dstTime:(NSTimeInterval)dstTime;
- (void)controlViewOnClickMute:(NELivePlayerControlView *)controlView isMute:(BOOL)isMute;
- (void)controlViewOnClickSnap:(NELivePlayerControlView *)controlView;
- (void)controlViewOnClickScale:(NELivePlayerControlView *)controlView isFill:(BOOL)isFill;
///< 点击全屏
- (void)clickFull:(NELivePlayerControlView *)controlView;
///< 投屏
- (void)searchTv;
- (void)getXl:(NSString*)url;
- (void)changeXianLuAtIndex: (NSInteger)index;
- (void)showXl:(NSArray *) jxs;

@end


