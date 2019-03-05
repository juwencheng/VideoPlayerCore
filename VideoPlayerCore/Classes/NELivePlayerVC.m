//
//  NELivePlayerVC.m
//  NELivePlayerDemo
//
//  Created by Netease on 2017/11/15.
//  Copyright © 2017年 netease. All rights reserved.
//

#import "NELivePlayerVC.h"
#import "NELivePlayerController.h"
#import "NELivePlayerControlView.h"
#import "LoadingView.h"
#import <WebKit/WebKit.h>
#import <MediaPlayer/MediaPlayer.h>
#import <AVFoundation/AVFoundation.h>
#import "ZFBrightnessView.h"
#import <HPCastLink/HPCastLink.h>
#import "AppDelegate.h"
#import "UIAlertController+Thunder.h"
#import "SQLiteManager.h"
#import "Masonry.h"
#import "VideoDetailView.h"
#import "MVideoVolume.h"
#import "AnalysisLogger.h"
#import "ShimmerLoadingView.h"
#import "HomeQiangpianViewController.h"
#import "CustomNavigationController.h"
#import "MethodProtocolExecutor.h"
#import "WebVC.h"
#import "NELivePlayerVC+Admob.h"

const static double VideoPlayerWidthAspect = 0.6;

    // 枚举值，包含水平移动方向和垂直移动方向
typedef NS_ENUM(NSInteger, PanDirection) {
    PanDirectionHorizontalMoved, // 横向移动
    PanDirectionVerticalMoved    // 纵向移动
};

@interface NELivePlayerVC () <WKScriptMessageHandler, UIGestureRecognizerDelegate, UIActionSheetDelegate> {
    NSString *_decodeType;
    NSString *_mediaType;
    BOOL _isHardware;
    dispatch_source_t _timer;
    NSArray *_xianlus; // 解析线路
}

@property(nonatomic, strong) NELivePlayerController *player; //播放器sdk

@property(nonatomic, strong) NSString *video_title;
@property(nonatomic, strong) NSURL *platformUrl; ///< 视频所在三方网站的链接
@property(nonatomic, strong) NSURL *url;

@property(nonatomic, strong) UIView *playerContainerView; //播放器包裹视图

@property(nonatomic, strong) NELivePlayerControlView *controlView; //播放器控制视图


@property(nonatomic, strong) ShimmerLoadingView *loadingView;
@property(nonatomic, assign) int is_full;
@property(nonatomic, assign) NSInteger xianluIndex;
@property(nonatomic, strong) WKWebView *extraRealVideoUrlWebView;

@property(nonatomic, assign) int is_init;
@property(nonatomic, assign) int is_loading;
@property(nonatomic, assign) int is_quit;
@property(nonatomic, strong) ZFBrightnessView *brightnessView;

/** 滑杆 */
@property(nonatomic, strong) UISlider *volumeViewSlider;

/** 定义一个实例变量，保存枚举值 */
@property(nonatomic, assign) PanDirection panDirection;
/** 用来保存快进的总时长 */
@property(nonatomic, assign) NSTimeInterval sumTime;
/** 是否在调节音量*/
@property(nonatomic, assign) BOOL isVolume;

@property(nonatomic, assign) BOOL isTv;

@property(nonatomic, strong) UIView *tvView;

/** 快进快退View*/
@property(nonatomic, strong) UIView *fastView;
/** 快进快退进度progress*/
@property(nonatomic, strong) UIProgressView *fastProgressView;
/** 快进快退时间*/
@property(nonatomic, strong) UILabel *fastTimeLabel;
/** 快进快退ImageView*/
@property(nonatomic, strong) UIImageView *fastImageView;

@property(nonatomic, assign) int is_zhibo;

@property(nonatomic, assign) int replayCount;


@property(nonatomic, strong) VideoDetailView *detailView;
@property(nonatomic, assign) NSInteger selectedVolume;

- (void)autoChangeXl;
@end

@interface NELivePlayerVC (Control)<NELivePlayerControlViewProtocol>

- (void)createGesture;
- (void)configureVolume;
- (void)setupFastView;
@end

@interface NELivePlayerVC (Volume) // 分集
- (void)setupDetailView;
- (void)requestVolumeList;
- (void)reloadVolumeList:(NSArray *)volumeList;
@end

@interface NELivePlayerVC (JieXi)

@end


@implementation NELivePlayerVC

- (instancetype)initWithURL:(NSURL *)url andDecodeParm:(NSMutableArray *)decodeParm {
    if (self = [self init]) {
//        _entryUrl = url;
        _platformUrl = url;
        _decodeType = [decodeParm objectAtIndex:0];
        _mediaType = [decodeParm objectAtIndex:1];
        _selectedVolume = -1;
        if (decodeParm.count == 4) {
            _video_title = [decodeParm objectAtIndex:2];
        } else {
            _video_title = @"-";
        }
        if ([_decodeType isEqualToString:@"hardware"]) {
            _isHardware = YES;
        } else if ([_decodeType isEqualToString:@"software"]) {
            _isHardware = NO;
        }
        _xianluIndex = [[decodeParm objectAtIndex:3] intValue];
        _is_quit = 0;
        _is_init = 0;
        _is_loading = 0;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // 屏幕常亮
    [[UIApplication sharedApplication] setIdleTimerDisabled:YES];
    self.navigationController.navigationBar.translucent = NO;
    
    _replayCount = 0;
    _is_full = 0;
    _is_zhibo = 0;
    [self setupSubviews];
    if ([_mediaType isEqualToString:@"livestream"]) {
        _url = _platformUrl;
        [self doInitPlayer];
        _is_zhibo = 1;
        [self doInitPlayerNotication];
        _is_init = 1;
    } else {
        [self getResource];
        [self requestVolumeList];
    }
    
    [self createGesture];
    [self.view addSubview:self.brightnessView];
    
        // 获取系统音量
    [self configureVolume];
    
    [self setupFastView];
    self.view.backgroundColor = [UIColor darkGrayColor];
    [self addChangeUrlNotification];
    [self requestChaye];
}

- (void)addChangeUrlNotification {
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(changeUrl:) name:@"ChangeVideoURLNotification" object:nil];
}

- (void)changeUrl:(NSNotification *)notification {
    NSDictionary *params = notification.object;
    NSInteger type = [params[@"type"] integerValue];
    NSString *title = params[@"title"];
    NSString *url = params[@"url"];
    NSMutableArray *decodeParm = [[NSMutableArray alloc] init];

    switch (type) {
        case 0: {
            [decodeParm addObject:@"software"];
            [decodeParm addObject:@"videoOnDemand"];
            [decodeParm addObject:title];
            NSString *ct = @"0";
            [decodeParm addObject:ct];
        }
            break;
        case 1: {
            [decodeParm addObject:@"software"];
            [decodeParm addObject:@"videoOnDemand"];
            [decodeParm addObject: title];
            NSString *ct = @"0";
            [decodeParm addObject:ct];
        }
            break;
        case 2: {
            [decodeParm addObject:@"software"];
            [decodeParm addObject:@"livestream"];
            [decodeParm addObject:title];
            NSString *ct = @"0";
            [decodeParm addObject:ct];
        }
            break;
        default:
            break;
    }
    [self changeURL:[NSURL URLWithString:url] decodeParam:decodeParm];
}

- (void)changeURL:(NSURL *)url decodeParam:(NSMutableArray *)decodeParam {
    if (url == nil) return;
    [self.player pause];
//    _entryUrl = url;
    _platformUrl = url;
    _decodeType = [decodeParam objectAtIndex:0];
    _mediaType = [decodeParam objectAtIndex:1];
    _selectedVolume = -1;
    if (decodeParam.count == 4) {
        _video_title = [decodeParam objectAtIndex:2];
    } else {
        _video_title = @"-";
    }
    if ([_decodeType isEqualToString:@"hardware"]) {
        _isHardware = YES;
    } else if ([_decodeType isEqualToString:@"software"]) {
        _isHardware = NO;
    }
    _xianluIndex = [[decodeParam objectAtIndex:3] intValue];
    _is_quit = 0;
    _is_init = 0;
    _is_loading = 0;
    
    _replayCount = 0;
    _is_full = 0;
    _is_zhibo = 0;
    
    // 重置controlView
    self.controlView.fileTitle = _video_title;
    self.controlView.isLineRoad = self.isLoadLine;
    
    // 重置detailView
    self.detailView.title = _video_title;
    self.detailView.videoUrl = self.platformUrl.absoluteString;
    
    if ([_mediaType isEqualToString:@"livestream"]) {
        _url = _platformUrl;
        [self doInitPlayer];
        _is_zhibo = 1;
        _is_init = 1;
    } else {
        [self getResource];
        [self requestVolumeList];
    }
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:YES];
}

- (void)viewWillDisappear:(BOOL)animated {
    [super viewWillDisappear:animated];
    [[UIApplication sharedApplication] setStatusBarHidden:NO];
}

- (void)dealloc {
    if (_player != nil && _player.isPlaying) {
        [_player pause];
    }
    
    NSLog(@"[闪电影视] NELivePlayerVC 已经释放！");
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)setupSubviews {
    [self setupPlayerContainerView];
    [self setupControlView];
    [self setupLoadingView];
    [self setupDetailView];
}

- (void)setupPlayerContainerView {
    _playerContainerView = [[UIView alloc] init];
    [self.view addSubview:_playerContainerView];
    [self.playerContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.leading.mas_equalTo(self.view);
        make.width.mas_equalTo(self.view.mas_width);
        make.height.mas_equalTo(SCREEN_WIDTH * VideoPlayerWidthAspect);
    }];
}

- (void)setupControlView {
    _controlView = [[NELivePlayerControlView alloc] init];
    _controlView.fileTitle = _video_title;
    _controlView.delegate = self;
    _controlView.isLineRoad = self.isLoadLine;
    [self.view addSubview:_controlView];
    [_controlView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.equalTo(_playerContainerView);
    }];
    __weak typeof(self) weakSelf = self;
    self.controlView.chooseVolume = ^(NSIndexPath * _Nonnull indexPath, MVideoVolume * _Nonnull volumeData) {
        weakSelf.selectedVolume = indexPath.row;
        [weakSelf chooseVolume:volumeData];
        weakSelf.detailView.selectedVolume = volumeData.order - 1;
    };
}

- (void)setupLoadingView {
//    LoadingView *loadingView = [[LoadingView alloc] initWithWebViewTitle:@"正在获取资源"];
    ShimmerLoadingView *loadingView = [[ShimmerLoadingView alloc] init];

    self.loadingView = loadingView;
    [self.playerContainerView addSubview:loadingView];
    [loadingView mas_makeConstraints:^(MASConstraintMaker *make) {
//        make.center.mas_equalTo(self.playerContainerView);
        make.edges.mas_equalTo(self.playerContainerView);
    }];
}

#pragma marks -- UIAlertViewDelegate --

    //根据被点击按钮的索引处理点击事件
- (void)alertView:(UIAlertView *)alertView clickedButtonAtIndex:(NSInteger)buttonIndex {
    if (buttonIndex == 1) {
        [[HPCastLink sharedCastLink] castStopPlay];
        _isTv = NO;
        if (_tvView != nil)
            [_tvView setHidden:YES];
    }
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



- (void)initPlayerWebView {
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"初始化解析视频的webView，并且注入js代码"] selector:_cmd];
    WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
    configuration.userContentController = [WKUserContentController new];
    [configuration.userContentController addScriptMessageHandler:self name:@"AppModel"];
    NSString *js;
    js = @"(function(w){w['dd_is_get']=false;var lis=setInterval(function(){searchVideos(w)},300);function searchVideos(win,src){var src=src||false;if(!src||src.indexOf(window.location.host)>0){var vd=win.document.getElementsByTagName('video');console.log('www:search_vd')}else{clearInterval(lis);toUrl(src);return}if(vd.length>0){var url=vd[0].getAttribute('src');if(url.indexOf('http')!=0){url=window.location.protocol+'//'+win.location.host+url}setUrl(url);clearInterval(lis);return}var ifs=win.document.getElementsByTagName('iframe');if(ifs.length>0){setTimeout(function(){for(var i=0;i<ifs.length;i++){searchVideos(win.frames[i],ifs[i].src)}},500);}}function toUrl(src){console.log('www:to_url');setTimeout(function(){window.location.href=src},2000);}function setUrl(v){if(w['dd_is_get'])return;w['dd_is_get']=true;if(window['Android']){var api=window['Android'];api.toplay(v)}else if(window['webkit']&&window.webkit['messageHandlers']){api=window.webkit.messageHandlers.AppModel;api.postMessage({'method':'play_real_video','params':v})}else{alert('www:get_vd'+v)}window.location.href='about:blank'}})(window);";
    
    
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:js injectionTime:WKUserScriptInjectionTimeAtDocumentEnd forMainFrameOnly:YES];// forMainFrameOnly:NO(全局窗口)，yes（只限主窗口）
    
    
    [configuration.userContentController addUserScript:userScript];
    _extraRealVideoUrlWebView = [[WKWebView alloc] initWithFrame:CGRectMake(0, 0, 0, 0) configuration:configuration];
    [self.view addSubview:_extraRealVideoUrlWebView];
    _extraRealVideoUrlWebView.backgroundColor = [UIColor clearColor];
}

#pragma mark - WKScriptMessageHandler

- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {
    NSLog(@"\nname：%@\nbody：%@", message.name, message.body);
    if ([message.name isEqualToString:@"AppModel"]) {
        if ([message.body isKindOfClass:[NSDictionary class]]) {
            NSMutableDictionary *dic = [NSMutableDictionary dictionaryWithDictionary:message.body];
            if ([dic[@"method"] isEqualToString:@"play_real_video"]) {
                if (_is_quit == 1) return;
                _is_loading = 0;
                __block NSString *url = dic[@"params"];
                [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"从网页获取到的视频地址是:%@", url] selector:_cmd];
                [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"将视频地址发送到服务器通过服务器处理"] selector:_cmd];
                [YQNetworking getWithUrl:[NSString stringWithFormat:@"%@%@&version=%@", BaseURL, @"/index.php?m=Home&c=Index&a=deal_url", APIVersion] refreshRequest:NO cache:NO params:@{@"platUrl": _platformUrl.absoluteString, @"videoUrl": url} progressBlock:nil successBlock:^(id response) {
                    NSLog(@"response：%@", response);
                    _url = [[NSURL alloc] initWithString:response[@"videoUrl"]];
                    [self readyToInitPlayer];
                }              failBlock:^(NSError *error) {
                    url = [url stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
                    _url = [[NSURL alloc] initWithString:url];
                    [self initPlayerWebView];
                }];
            }
        }
    }
}

- (void)readyToInitPlayer {
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"播放地址是: %@", _url.absoluteString] selector:_cmd];
    if (_is_init == 0) {
        [self doInitPlayer];
        [self doInitPlayerNotication];
        _is_init = 1;
    } else {
        [_player switchContentUrl:_url];
    }
}

- (void)chooseVolume:(MVideoVolume *)volume {
    [SVProgressHUD showWithStatus:@"切换分集中"];
        // 暂停播放
    if (self.player.isPlaying) {
        [self.player pause];
    }
        // 设置url
    _platformUrl = [NSURL URLWithString:volume.url];
        // 获取资源
    [self getResource];
    
        // 设置标题
    self.controlView.fileTitle = [NSString stringWithFormat:@"%@ %@", _video_title, @(volume.order)];
}

- (void)getResource {
        // 获取资源链接，选集的时候，只需要重新设置_surl，调用getResource即可
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:TOKEN_KEY];
    if (!token) token = @"";
    NSString *url = [NSString stringWithFormat:@"%@index.php", BaseURL];
    NSLog(@"播放url：%@", _platformUrl);
    NSDictionary *params = @{
                             @"m": @"Home",
                             @"c": @"Index",
                             @"a": @"get_resource2",
                             @"token": token,
                             @"url": _platformUrl
                             };
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"\n😀开始获取后台自定义的解析源😀"] selector:_cmd];
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"视频标题：%@", self.video_title] selector:_cmd];
    
    [YQNetworking postWithUrl:url refreshRequest:NO cache:NO params:params progressBlock:nil successBlock:^(id response) {
        
        NSLog(@"response：%@", response);
        if ([response isKindOfClass:[NSDictionary class]]) {
            
            if ([response[@"code"] isEqualToString:@"error"]) {
                if ([response objectForKey:@"msg"]) {
                    [SVProgressHUD showErrorWithStatus:response[@"msg"]];
                    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"获取后台自定义的解析源失败 : %@", response[@"msg"]] selector:_cmd];
                    [self dismissViewControllerAnimated:YES completion:nil];
                }
            } else {
                if ([response objectForKey:@"data"]) {
                    _xianlus = response[@"data"][@"xianlu"];
                    // 尝试视频能否播放
                    NSString *realUrl = response[@"data"][@"url"];
                    [_controlView initJxWithJxs:_xianlus ct:_xianluIndex];
                    [SVProgressHUD dismiss];
                    if ([realUrl isKindOfClass:[NSString class]] && realUrl.length > 0) {
                        _url = [[NSURL alloc] initWithString:realUrl];
                        [self readyToInitPlayer];
                    }else {
//                        NSDictionary *jx = _xianlus[_ct];
//                        [self getXl:jx[@"url"]];
                        [self changeXianLuAtIndex:_xianluIndex];
                    }
                }
            }
            
        }
    }               failBlock:^(NSError *error) {
            //        [SVProgressHUD showErrorWithStatus:@"网络连接中断"];
    }];
}

- (BOOL)shouldAutorotate {
    return NO;
}

- (BOOL)prefersStatusBarHidden {
    return YES;
}

- (void)syncUIStatus {
    _controlView.isPlaying = NO;
    
    __block NSTimeInterval mDuration = 0;
    __block bool getDurFlag = false;
    __weak typeof(self) weakSelf = self;
    dispatch_queue_t syncUIQueue = dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0);
    _timer = CreateDispatchSyncUITimerN(1.0, syncUIQueue, ^{
        dispatch_async(dispatch_get_main_queue(), ^{
            if (!getDurFlag) {
                mDuration = [weakSelf.player duration];
                if (mDuration > 0) {
                    getDurFlag = true;
                }
            }
            weakSelf.controlView.isAllowSeek = (mDuration > 0);
            weakSelf.controlView.duration = mDuration;
            weakSelf.controlView.currentPos = [weakSelf.player currentPlaybackTime];
            weakSelf.controlView.isPlaying = ([weakSelf.player playbackState] == NELPMoviePlaybackStatePlaying);
        });
    });
}

#pragma mark - 播放器SDK功能

- (void)doInitPlayer {
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"初始化视频播放器，并调用prepareToPlay"] selector:_cmd];
    [NELivePlayerController setLogLevel:NELP_LOG_VERBOSE];
    
    NSError *error = nil;
    if (self.player) {
        [self.player pause];
        [self.player shutdown];
        [self.player.view removeFromSuperview];
    }
    [AnalysisLogger uploadVideoUrl:_url.absoluteString platformUrl: _platformUrl.absoluteString];
    self.player = [[NELivePlayerController alloc] initWithContentURL:_url error:&error];
    if (self.player == nil) {
        NSLog(@"player initilize failed, please tay again.error = [%@]!", error);
    }
    self.player.view.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    self.player.view.frame = _playerContainerView.bounds;
    [_playerContainerView addSubview:self.player.view];
    
    self.view.autoresizesSubviews = YES;
    [self.player setScalingMode:NELPMovieScalingModeNone]; // 设置画面显示模式，默认原始大小
    [self.player setShouldAutoplay:YES]; // 设置prepareToPlay完成后是否自动播放
    [self.player setHardwareDecoder:_isHardware]; // 设置解码模式，是否开启硬件解码
    [self.player setPauseInBackground:YES]; // 设置切入后台时的状态，暂停还是继续播放
    [self.player setPlaybackTimeout:15 * 1000]; // 设置拉流超时时间
    
    if ([_mediaType isEqualToString:@"livestream"]) {
        [self.player setBufferStrategy:NELPLowDelay]; // 直播低延时模式
    } else {
        [self.player setBufferStrategy:NELPAntiJitter]; // 点播抗抖动
    }
    
    
#ifdef KEY_IS_KNOWN // 视频云加密的视频，自己已知密钥
    NSString *key = @"HelloWorld";
    NSData *keyData = [key dataUsingEncoding:NSUTF8StringEncoding];
    Byte *flv_key = (Byte *)[keyData bytes];
    
    unsigned long len = [keyData length];
    flv_key[len] = '\0';
    __weak typeof(self) weakSelf = self;
    [self.player setDecryptionKey:flv_key andKeyLength:(int)len :^(NELPKeyCheckResult ret) {
        if (ret == 0 || ret == 1) {
            [weakSelf.liveplayer prepareToPlay];
        }
    }];
    
#else
    
#ifdef DECRYPT //用视频云整套加解密系统
    if ([self.mediaType isEqualToString:@"videoOnDemand"]) {
        NSString *transferToken = NULL;
        NSString *accid = NULL;
        NSString *appKey = NULL;
        NSString *token = NULL;
        [self.liveplayer initDecryption:transferToken :accid :appKey :token :^(NELPKeyCheckResult ret) {
            NSLog(@"ret = %d", ret);
            switch (ret) {
                case NELP_NO_ENCRYPTION:
                case NELP_ENCRYPTION_CHECK_OK:
                    [self.liveplayer prepareToPlay];
                    break;
                case NELP_ENCRYPTION_UNSUPPORT_PROTOCAL:
                    [self decryptWarning:@"NELP_ENCRYPTION_UNSUPPORT_PROTOCAL"];
                    break;
                case NELP_ENCRYPTION_KEY_CHECK_ERROR:
                    [self decryptWarning:@"NELP_ENCRYPTION_KEY_CHECK_ERROR"];
                    break;
                case NELP_ENCRYPTION_INPUT_INVALIED:
                    [self decryptWarning:@"NELP_ENCRYPTION_INPUT_INVALIED"];
                    break;
                case NELP_ENCRYPTION_UNKNOWN_ERROR:
                    [self decryptWarning:@"NELP_ENCRYPTION_UNKNOWN_ERROR"];
                    break;
                case NELP_ENCRYPTION_GET_KEY_TIMEOUT:
                    [self decryptWarning:@"NELP_ENCRYPTION_GET_KEY_TIMEOUT"];
                    break;
                default:
                    break;
            }
        }];
    }
#else
    [self.player prepareToPlay];
#endif
#endif
}

- (void)doInitPlayerNotication {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerDidPreparedToPlay:)
                                                 name:NELivePlayerDidPreparedToPlayNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerPlaybackStateChanged:)
                                                 name:NELivePlayerPlaybackStateChangedNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NeLivePlayerloadStateChanged:)
                                                 name:NELivePlayerLoadStateChangedNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerPlayBackFinished:)
                                                 name:NELivePlayerPlaybackFinishedNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerFirstVideoDisplayed:)
                                                 name:NELivePlayerFirstVideoDisplayedNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerFirstAudioDisplayed:)
                                                 name:NELivePlayerFirstAudioDisplayedNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerReleaseSuccess:)
                                                 name:NELivePlayerReleaseSueecssNotification
                                               object:nil];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerVideoParseError:)
                                                 name:NELivePlayerVideoParseErrorNotification
                                               object:_player];
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(NELivePlayerSeekComplete:)
                                                 name:NELivePlayerMoviePlayerSeekCompletedNotification
                                               object:_player];
}

- (void)doDestroyPlayer {
    [self.player shutdown]; // 退出播放并释放相关资源
    [self.player.view removeFromSuperview];
    self.player = nil;
}

- (ZFBrightnessView *)brightnessView {
    if (!_brightnessView) {
        _brightnessView = [ZFBrightnessView sharedBrightnessView];
    }
    return _brightnessView;
}

- (UIView *)fastView {
    if (!_fastView) {
        _fastView = [[UIView alloc] initWithFrame:CGRectMake((kScreenWidth - 125) / 2, (kScreenHeight - 80) / 2, 125, 80)];
        _fastView.backgroundColor = RGBA(0, 0, 0, 0.8);
        _fastView.layer.cornerRadius = 4;
        _fastView.layer.masksToBounds = YES;
    }
    return _fastView;
}

- (UIImageView *)fastImageView {
    if (!_fastImageView) {
        _fastImageView = [[UIImageView alloc] initWithFrame:CGRectMake(47, 5, 32, 32)];
    }
    return _fastImageView;
}

- (UILabel *)fastTimeLabel {
    if (!_fastTimeLabel) {
        _fastTimeLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, 39, 125, 20)];
        _fastTimeLabel.textColor = [UIColor whiteColor];
        _fastTimeLabel.textAlignment = NSTextAlignmentCenter;
        _fastTimeLabel.font = [UIFont systemFontOfSize:14.0];
    }
    
    return _fastTimeLabel;
}

- (UIProgressView *)fastProgressView {
    if (!_fastProgressView) {
        _fastProgressView = [[UIProgressView alloc] initWithFrame:CGRectMake(14, 69, 100, 2)];
        _fastProgressView.progressTintColor = [UIColor whiteColor];
        _fastProgressView.trackTintColor = [[UIColor lightGrayColor] colorWithAlphaComponent:0.4];
    }
    return _fastProgressView;
}

#pragma mark - 播放器通知事件

- (void)hideLoadingView {
    _loadingView.isAnimating = NO;
    [_loadingView setHidden:YES];
}

- (void)presentLoadingView {
    [self.playerContainerView bringSubviewToFront:_loadingView];
    [_loadingView setHidden:NO];
    _loadingView.isAnimating = YES;
        //    _loadingView.loading_tv.text = @"正在切换资源";
}

- (void)NELivePlayerDidPreparedToPlay:(NSNotification *)notification {
        //add some methods
    NSLog(@"[闪电影视] 收到 NELivePlayerDidPreparedToPlayNotification 通知");
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"视频已经准备好，立即调用播放视频方法"] selector:_cmd];
    [self syncUIStatus];
    if (_is_zhibo == 0) {
        NSString *sql = [NSString stringWithFormat:@"select * from history where url='%@'", _platformUrl];
        NSMutableArray *his = [[SQLiteManager shareInstance] selectWithUrl:sql];
        if ([his count] == 1) {
            NSDictionary *hi = his[0];
            long seek = [hi[@"seek"] longValue];
            [_player setCurrentPlaybackTime:seek];
            
        }
    }
    
    
    [_player play]; //开始播放
    [self hideLoadingView];
    
        //开
    [_player setRealTimeListenerWithIntervalMS:500 callback:^(NSTimeInterval realTime) {
        NSLog(@"当前时间戳：[%f]", realTime);
    }];
    
        //关
    [_player setRealTimeListenerWithIntervalMS:500 callback:nil];
    
}

- (void)NELivePlayerPlaybackStateChanged:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerPlaybackStateChangedNotification 通知");
}

- (void)NeLivePlayerloadStateChanged:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerLoadStateChangedNotification 通知");
    
    NELPMovieLoadState nelpLoadState = _player.loadState;
    
    if (nelpLoadState == NELPMovieLoadStatePlaythroughOK) {
        NSLog(@"finish buffering");
        _controlView.isBuffing = NO;
    } else if (nelpLoadState == NELPMovieLoadStateStalled) {
        NSLog(@"begin buffering");
        _controlView.isBuffing = YES;
    }
}

- (void)NELivePlayerPlayBackFinished:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerPlaybackFinishedNotification 通知");
    
    UIAlertController *alertController = NULL;
    UIAlertAction *action = NULL;
    __weak typeof(self) weakSelf = self;
    switch ([[[notification userInfo] valueForKey:NELivePlayerPlaybackDidFinishReasonUserInfoKey] intValue]) {
        case NELPMovieFinishReasonPlaybackEnded:
            if ([_mediaType isEqualToString:@"livestream"]) {
                alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"直播结束" preferredStyle:UIAlertControllerStyleAlert];
                action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
                    [weakSelf doDestroyPlayer];
                    [weakSelf dismissViewControllerAnimated:YES completion:nil];
                }];
                [alertController addAction:action];
                alertController.popoverPresentationController.sourceView = weakSelf.view;
                [weakSelf presentViewController:alertController animated:YES completion:nil];
            }
            [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"视频已播放完，结束播放"] selector:_cmd];
            break;
            
        case NELPMovieFinishReasonPlaybackError: {
            
            
            
            
                //            alertController = [UIAlertController alertControllerWithTitle:@"注意" message:@"该解析资源不可用，请切换解析线路重试" preferredStyle:UIAlertControllerStyleAlert];
                //            action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action){
                //                [weakSelf doDestroyPlayer];
                //                [weakSelf dismissViewControllerAnimated:YES completion:nil];
                //            }];
                //            [alertController addAction:action];
                //            [weakSelf presentViewController:alertController animated:YES completion:nil];
            [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(checkVideoPlayStatus) target:self argument:nil];
            if ([self isBlankString:self.isLoadLine]) {
                [self autoChangeXl];
            }
            [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"视频播放失败，错误信息为：%@", notification.userInfo] selector:_cmd];
            break;
        }
            
        case NELPMovieFinishReasonUserExited:
            break;
            
        default:
            break;
    }
}

- (void)NELivePlayerFirstVideoDisplayed:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerFirstVideoDisplayedNotification 通知");
}

- (void)NELivePlayerFirstAudioDisplayed:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerFirstAudioDisplayedNotification 通知");
}

- (void)NELivePlayerVideoParseError:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerVideoParseError 通知");
    [self autoChangeXl];
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"视频解析失败"] selector:_cmd];
}

- (void)NELivePlayerSeekComplete:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerMoviePlayerSeekCompletedNotification 通知");
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"修改视频播放位置成功"] selector:_cmd];
}

- (void)NELivePlayerReleaseSuccess:(NSNotification *)notification {
    NSLog(@"[闪电影视] 收到 NELivePlayerReleaseSueecssNotification 通知");
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"播放器释放成功"] selector:_cmd];
}



#pragma mark - Tools

dispatch_source_t CreateDispatchSyncUITimerN(double interval, dispatch_queue_t queue, dispatch_block_t block) {
        //创建Timer
    dispatch_source_t timer = dispatch_source_create(DISPATCH_SOURCE_TYPE_TIMER, 0, 0, queue);//queue是一个专门执行timer回调的GCD队列
    if (timer) {
            //使用dispatch_source_set_timer函数设置timer参数
        dispatch_source_set_timer(timer, dispatch_time(DISPATCH_TIME_NOW, interval * NSEC_PER_SEC), interval * NSEC_PER_SEC, (1ull * NSEC_PER_SEC) / 10);
            //设置回调
        dispatch_source_set_event_handler(timer, block);
            //dispatch_source默认是Suspended状态，通过dispatch_resume函数开始它
        dispatch_resume(timer);
    }
    
    return timer;
}

- (void)decryptWarning:(NSString *)msg {
    UIAlertController *alertController = NULL;
    UIAlertAction *action = NULL;
    
    alertController = [UIAlertController alertControllerWithTitle:@"注意" message:msg preferredStyle:UIAlertControllerStyleAlert];
    action = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
        if (self.presentingViewController) {
            [self.presentingViewController dismissViewControllerAnimated:YES completion:nil];
        }
    }];
    [alertController addAction:action];
    [self presentViewController:alertController animated:YES completion:nil];
}

@end

#pragma mark - 投屏
@implementation NELivePlayerVC (Mirror)

@end

#pragma mark - 播放控制相关
@implementation NELivePlayerVC (Control)

- (void)changeXianLuAtIndex:(NSInteger)index {
    if (_xianlus.count == 0)
        return;
    index = index % _xianlus.count;

    NSDictionary *xianlu = _xianlus[index];
    NSString *url = xianlu[@"url"];
    [self presentLoadingView];
    if (_is_init == 1) {
        if (_player.isPlaying) [_player pause];
    }
    
    if (_extraRealVideoUrlWebView == nil) {
        [self initPlayerWebView];
    }
    // 这里可能有问题? 处理直播的，暂时没有启用直播功能
    if (![self isBlankString:self.isLoadLine]) {
        url = _platformUrl.absoluteString;
    }
    
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"开始通过WebView解析视频，地址为：%@", url] selector:_cmd];
    [_extraRealVideoUrlWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self performSelector:@selector(checkVideoPlayStatus) withObject:nil/*可传任意类型参数*/ afterDelay:15.0];
    _is_loading = 1;
    _xianluIndex = index;
}

- (void)getXl:(NSString *)url {
    [self presentLoadingView];
//    [self.playerContainerView bringSubviewToFront:_loadingView.view];
//    [_loadingView.view setHidden:NO];
//    _loadingView.loading_tv.text = @"正在切换资源";
    if (_is_init == 1) {
        if (_player.isPlaying) [_player pause];
    }
    
    if (_extraRealVideoUrlWebView == nil) {
        [self initPlayerWebView];
    }
    if (![self isBlankString:self.isLoadLine]) {
        url = _platformUrl.absoluteString;
    }
    
        //    if ([url rangeOfString:@"v.qq"].location != NSNotFound || [url rangeOfString:@"filsohu.com"].location != NSNotFound) {
        //        NSArray *arr = [url componentsSeparatedByString:@"url="];
        //        url = [NSString stringWithFormat:@"%@url=%@",arr[0],_surl];
        //    }
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"开始通过WebView解析视频，地址为：%@", url] selector:_cmd];
    [_extraRealVideoUrlWebView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:url]]];
    [self performSelector:@selector(checkVideoPlayStatus) withObject:nil/*可传任意类型参数*/ afterDelay:15.0];
    _is_loading = 1;
}

- (void)checkVideoPlayStatus {
    if (_is_loading == 1) {
        [self hideLoadingView];
        [SVProgressHUD dismiss];
        _is_loading = 0;
        [self autoChangeXl];
//        [SVProgressHUD showErrorWithStatus:@"资源获取失败，点击右上角切换线路！"];
    }
}

- (void)autoChangeXl {
    if (self.player.isPlaying || self.player == nil) {
        return ;
    }
    if (_replayCount < _xianlus.count) {
        [SVProgressHUD showErrorWithStatus:@"解析资源失败，正在为您自动切换线路"];
//        [[NSNotificationCenter defaultCenter] postNotificationName:@"autoChangeLine" object:@{@"index": @(_xianluIndex+_replayCount)}];
        [self changeXianLuAtIndex:_xianluIndex];
        [self.controlView changeXianLuTitleAtIndex:_xianluIndex];
        _replayCount++;
        _xianluIndex = (_xianluIndex + 1 )  % _xianlus.count;
        NSLog(@"自动切换线路：%@", @(_replayCount));
    }else {
        [SVProgressHUD showErrorWithStatus:@"视频解析失败，请点击右上角切换线路"];
        [self hideLoadingView];
        _replayCount = 0;
    }
}

- (void)searchTv {
    if (!_isTv) {
        if (_url != nil) {
            [[HPCastLink sharedCastLink] castStartPlay:HPCastMediaTypeVideo url:_url.absoluteString startPosition:0 superViewController:self completeBlock:^(HPCastMirrorResults response) {
                if (response == HPCastMirrorResultCastURLSucceed) {
                    _isTv = YES;
                    [_player pause];
                    [[HPCastLink sharedCastLink] hideCastLinkView];
                    if (_tvView == nil) {
                        _tvView = [[UIView alloc] initWithFrame:CGRectMake(0, 40, self.view.bounds.size.width, self.view.bounds.size.height - 90)];
                        _tvView.backgroundColor = [UIColor blackColor];
                        
                        UIButton *fullBtn = [UIButton buttonWithType:UIButtonTypeCustom];
                        [fullBtn setImage:[UIImage imageNamed:@"icon_large_tv"] forState:UIControlStateNormal];
                        
                        UIImageView *iv = [[UIImageView alloc] initWithFrame:CGRectMake(self.view.bounds.size.width * 0.5 - 50, self.view.bounds.size.height * 0.4 - 100, 100, 80)];
                        [iv setImage:[UIImage imageNamed:@"icon_large_tv"]];
                        
                        [_tvView addSubview:iv];
                        
                        UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(self.view.bounds.size.width * 0.5 - 50, self.view.bounds.size.height * 0.4, 100, 30)];
                        label.layer.cornerRadius = 5;
                        label.textColor = [UIColor lightTextColor];
                        label.backgroundColor = [UIColor darkGrayColor];
                        label.text = @"退出投屏";
                        label.textAlignment = NSTextAlignmentCenter;
                        label.clipsToBounds = YES;
                        [_tvView addSubview:label];
                        
                        UITapGestureRecognizer *labelTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(exitTv)];
                        [label addGestureRecognizer:labelTapGestureRecognizer];
                        label.userInteractionEnabled = YES; // 可以理解为设置label可被点击
                        
                        [self.view addSubview:_tvView];
                    } else {
                        [_tvView setHidden:NO];
                    }
                }
            }];
        }
    } else {
            //初始化AlertView
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"提示"
                                                        message:@"正在投屏，确定要退出投屏吗"
                                                       delegate:self
                                              cancelButtonTitle:@"取消"
                                              otherButtonTitles:@"确定", nil];
        [alert show];
        
    }
}

- (void)exitTv {
    [[HPCastLink sharedCastLink] castStopPlay];
    _isTv = NO;
    if (_tvView != nil) {
        [_tvView setHidden:YES];
    }
}

- (void)clickFull:(NELivePlayerControlView *)controlView {
    if (_is_full == 1) {
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
        _is_full = 0;
        [_controlView cancelFull];
//        _brightnessView.frame = CGRectMake((kScreenWidth - 155) / 2, (kScreenHeight - 155) / 2, 155, 155);
//        _fastView.frame = CGRectMake((kScreenWidth - 125) / 2, (kScreenHeight - 80) / 2, 125, 80);
//        _loadingView.frame = CGRectMake((kScreenWidth - 200) / 2, (kScreenHeight - 100) / 2, 200, 100);
        return;
    } else {
        
        UIDeviceOrientation orientation = [UIDevice currentDevice].orientation;
        if (orientation == UIDeviceOrientationLandscapeRight) {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeLeft];
        } else {
            [self interfaceOrientation:UIInterfaceOrientationLandscapeRight];
        }
        [_controlView setFull];
        
//        _brightnessView.frame = CGRectMake((kScreenWidth - 155) / 2, (kScreenHeight - 155) / 2, 155, 155);
//        _fastView.frame = CGRectMake((kScreenWidth - 125) / 2, (kScreenHeight - 80) / 2, 125, 80);
//        _loadingView.frame = CGRectMake((kScreenWidth - 200) / 2, (kScreenHeight - 100) / 2, 200, 100);
        _is_full = 1;
    }
}

    // 进入全屏
#pragma mark 屏幕转屏相关

/**
 *  屏幕转屏
 *
 *  @param orientation 屏幕方向
 */
- (void)interfaceOrientation:(UIInterfaceOrientation)orientation {
    if (orientation == UIInterfaceOrientationLandscapeRight || orientation == UIInterfaceOrientationLandscapeLeft) {
            // 设置横屏
        [self setOrientationLandscapeConstraint:orientation];
    } else if (orientation == UIInterfaceOrientationPortrait) {
            // 设置竖屏
        [self setOrientationPortraitConstraint];
    }
}

/**
 *  设置横屏的约束
 */
- (void)setOrientationLandscapeConstraint:(UIInterfaceOrientation)orientation {
    [self toOrientation:orientation];
    _is_full = 1;
}

- (void)toOrientation:(UIInterfaceOrientation)orientation {
        // 获取到当前状态条的方向
    UIInterfaceOrientation currentOrientation = [UIApplication sharedApplication].statusBarOrientation;
        // 判断如果当前方向和要旋转的方向一致,那么不做任何操作
    if (currentOrientation == orientation) {return;}
    
        // 根据要旋转的方向,使用Masonry重新修改限制
    if (orientation != UIInterfaceOrientationPortrait) {//
        
        
    }
        // iOS6.0之后,设置状态条的方法能使用的前提是shouldAutorotate为NO,也就是说这个视图控制器内,旋转要关掉;
        // 也就是说在实现这个方法的时候-(BOOL)shouldAutorotate返回值要为NO
    [[UIApplication sharedApplication] setStatusBarOrientation:orientation animated:NO];
        // 获取旋转状态条需要的时间:
    [UIView beginAnimations:nil context:nil];
    [UIView setAnimationDuration:0.3];
        // 更改了状态条的方向,但是设备方向UIInterfaceOrientation还是正方向的,这就要设置给你播放视频的视图的方向设置旋转
        // 给你的播放视频的view视图设置旋转
    self.view.transform = CGAffineTransformIdentity;
    self.view.transform = [self getTransformThunderAngle];
        // 开始旋转
    [UIView commitAnimations];
    
    if (orientation != UIInterfaceOrientationPortrait) {//
        self.view.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
        
            //        _playerContainerView.frame = CGRectMake(0, 0, kScreenHeight, kScreenWidth);
        [self.playerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
            make.leading.top.mas_equalTo(self.view);
            make.width.mas_equalTo(self.view.mas_width);
            make.height.mas_equalTo(kScreenHeight);
        }];
            //        [self.playerContainerView mas_makeConstraints:^(MASConstraintMaker *make) {
            //            make.width.mas_equalTo(kScreenHeight);
            //            make.height.mas_equalTo(self.view.mas_height);
            //        }];
        [UIView animateWithDuration:0.25 animations:^{
                //            self.playlistView.alpha = 0;
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        }];
    } else {
        self.view.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
            //        _playerContainerView.frame = CGRectMake(0, 0, kScreenWidth, kScreenHeight);
        [self.playerContainerView mas_remakeConstraints:^(MASConstraintMaker *make) {
                //            make.width.mas_equalTo(SCREEN_WIDTH);
            make.leading.top.mas_equalTo(self.view);
            make.width.mas_equalTo(self.view.mas_width);
            make.height.mas_equalTo(kScreenWidth * VideoPlayerWidthAspect);
        }];
        [UIView animateWithDuration:0.25 animations:^{
                //            self.playlistView.alpha = 1;
            [self.view setNeedsLayout];
            [self.view layoutIfNeeded];
        } completion:^(BOOL finished) {
        }];
    }
    
}

/**
 * 获取变换的旋转角度
 *
 * @return 角度
 */
- (CGAffineTransform)getTransformThunderAngle {
        // 状态条的方向已经设置过,所以这个就是你想要旋转的方向
    UIInterfaceOrientation orientation = [UIApplication sharedApplication].statusBarOrientation;
        // 根据要进行旋转的方向来计算旋转的角度
    if (orientation == UIInterfaceOrientationPortrait) {
        return CGAffineTransformIdentity;
    } else if (orientation == UIInterfaceOrientationLandscapeLeft) {
        return CGAffineTransformMakeRotation(-M_PI_2);
    } else if (orientation == UIInterfaceOrientationLandscapeRight) {
        return CGAffineTransformMakeRotation(M_PI_2);
    }
    return CGAffineTransformIdentity;
}

/**
 *  设置竖屏的约束
 */
- (void)setOrientationPortraitConstraint {
    [self toOrientation:UIInterfaceOrientationPortrait];
    _is_full = 0;
}

/**
 *  创建手势
 */
- (void)createGesture {
        // 添加平移手势，用来控制音量、亮度、快进快退
    UIPanGestureRecognizer *panRecognizer = [[UIPanGestureRecognizer alloc] initWithTarget:self action:@selector(panDirection:)];
    panRecognizer.delegate = self;
    [panRecognizer setMaximumNumberOfTouches:1];
    [panRecognizer setDelaysTouchesBegan:YES];
    [panRecognizer setDelaysTouchesEnded:YES];
    [panRecognizer setCancelsTouchesInView:YES];
    [self.view addGestureRecognizer:panRecognizer];
}

/**
 *  获取系统音量
 */
- (void)configureVolume {
    MPVolumeView *volumeView = [[MPVolumeView alloc] init];
    _volumeViewSlider = nil;
    for (UIView *view in [volumeView subviews]) {
        if ([view.class.description isEqualToString:@"MPVolumeSlider"]) {
            _volumeViewSlider = (UISlider *) view;
            break;
        }
    }
    
        // 使用这个category的应用不会随着手机静音键打开而静音，可在手机静音下播放声音
    NSError *setCategoryError = nil;
    BOOL success = [[AVAudioSession sharedInstance]
                    setCategory:AVAudioSessionCategoryPlayback
                    error:&setCategoryError];
    
    if (!success) { /* handle the error in setCategoryError */ }
}

- (void)setupFastView {
    [self.view addSubview:self.fastView];
    [self.fastView addSubview:self.fastImageView];
    [self.fastView addSubview:self.fastTimeLabel];
    [self.fastView addSubview:self.fastProgressView];
    
    _fastView.hidden = YES;
}

#pragma mark - 控制页面的事件

- (void)controlViewOnClickQuit:(NELivePlayerControlView *)controlView {
    NSLog(@"[NELivePlayer] 点击退出");
    if (_is_full == 1) {
        [self interfaceOrientation:UIInterfaceOrientationPortrait];
        _is_full = 0;
        [_controlView cancelFull];
            //        _brightnessView.frame = CGRectMake((kScreenWidth - 155) / 2, (kScreenHeight - 155) / 2, 155, 155);
            //
            //        _loadingView.view.frame = CGRectMake((kScreenWidth - 200) / 2, (kScreenHeight - 100) / 2, 200, 100);
            //        _fastView.frame = CGRectMake((kScreenWidth - 125) / 2, (kScreenHeight - 80) / 2, 125, 80);
        return;
    }
    
    long all = 0;
    long seek = 0;
    
    if (_player != nil && [_player isPreparedToPlay]) {
        seek = _player.currentPlaybackTime;
        all = _player.duration;
    }
    if (_is_zhibo == 0) {
        [[SQLiteManager shareInstance] addHistoryWithUrl:_platformUrl.absoluteString title:_video_title all:all seek:seek];
    }
    [self exitTv];
    [self doDestroyPlayer];
    
        // 释放timer
    if (_timer != nil) {
        dispatch_source_cancel(_timer);
        _timer = nil;
    }
    [[NSRunLoop currentRunLoop] cancelPerformSelector:@selector(checkVideoPlayStatus) target:self argument:nil];
    [self.extraRealVideoUrlWebView.configuration.userContentController removeScriptMessageHandlerForName:@"AppModel"];
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    _is_quit = 1;
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (void)controlViewOnClickPlay:(NELivePlayerControlView *)controlView isPlay:(BOOL)isPlay {
    NSLog(@"[闪电影视] 点击播放，当前状态: [%@]", (isPlay ? @"播放" : @"暂停"));
    if (isPlay) {
        [self.player play];
    } else {
        [self presentChaye];
        [self.player pause];
    }
}

- (void)controlViewOnClickSeek:(NELivePlayerControlView *)controlView dstTime:(NSTimeInterval)dstTime {
    NSLog(@"[闪电影视] 执行seek，目标时间: [%f]", dstTime);
    self.player.currentPlaybackTime = dstTime;
}

- (void)controlViewOnClickMute:(NELivePlayerControlView *)controlView isMute:(BOOL)isMute {
    NSLog(@"[闪电影视] 点击静音，当前状态: [%@]", (isMute ? @"静音开" : @"静音关"));
    [self.player setMute:isMute];
}

- (void)controlViewOnClickSnap:(NELivePlayerControlView *)controlView {
    
    NSLog(@"[闪电影视] 点击屏幕截图");
    
    UIImage *snapImage = [self.player getSnapshot];
    
    UIImageWriteToSavedPhotosAlbum(snapImage, nil, nil, nil);
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:@"截图已保存到相册" preferredStyle:UIAlertControllerStyleAlert];
    
    UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:^(UIAlertAction *action) {
    }];
    [alertController addAction:action];
    alertController.popoverPresentationController.sourceView = self.view;
    [self presentViewController:alertController animated:YES completion:nil];
}

- (void)controlViewOnClickScale:(NELivePlayerControlView *)controlView isFill:(BOOL)isFill {
    NSLog(@"[闪电影视] 点击屏幕缩放，当前状态: [%@]", (isFill ? @"全屏" : @"适应"));
    if (isFill) {
        [self.player setScalingMode:NELPMovieScalingModeAspectFill];
    } else {
        [self.player setScalingMode:NELPMovieScalingModeAspectFit];
    }
}

- (void)showXl:(NSArray *)jxs {
    
}


#pragma mark - UIPanGestureRecognizer手势方法

/**
 *  pan手势事件
 *
 *  @param pan UIPanGestureRecognizer
 */

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldReceiveTouch:(UITouch *)touch {
        // 支持选集的滚动，和点击广告事件响应
    if ([touch.view isKindOfClass:[UICollectionView class]] || touch.view.tag == 10) {
        return YES;
    }
    if ([touch.view isKindOfClass:[UISlider class]] || [touch.view isKindOfClass:[UIScrollView class]]) {
        return NO;
    }
    return YES;
}

- (void)panDirection:(UIPanGestureRecognizer *)pan {
    
        //根据在view上Pan的位置，确定是调音量还是亮度
    CGPoint locationPoint = [pan locationInView:self.view];
    
        // 我们要响应水平移动和垂直移动
        // 根据上次和本次移动的位置，算出一个速率的point
    CGPoint veloctyPoint = [pan velocityInView:self.view];
    
        // 判断是垂直移动还是水平移动
    switch (pan.state) {
        case UIGestureRecognizerStateBegan: { // 开始移动
                                              // 使用绝对值来判断移动的方向
            CGFloat x = fabs(veloctyPoint.x);
            CGFloat y = fabs(veloctyPoint.y);
            if (x > y) { // 水平移动
                         // 取消隐藏
                if (_is_init == 0) return;
                self.panDirection = PanDirectionHorizontalMoved;
                self.sumTime = [_player currentPlaybackTime];
                
            } else if (x < y) { // 垂直移动
                self.panDirection = PanDirectionVerticalMoved;
                    // 开始滑动的时候,状态改为正在控制音量
                if (locationPoint.x > self.view.bounds.size.width / 2) {
                    self.isVolume = YES;
                } else { // 状态改为显示亮度调节
                    self.isVolume = NO;
                }
            }
            break;
        }
        case UIGestureRecognizerStateChanged: { // 正在移动
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved: {
                    [self horizontalMoved:veloctyPoint.x]; // 水平移动的方法只要x方向的值
                    break;
                }
                case PanDirectionVerticalMoved: {
                    [self verticalMoved:veloctyPoint.y]; // 垂直移动方法只要y方向的值
                    break;
                }
                default:
                    break;
            }
            break;
        }
        case UIGestureRecognizerStateEnded: { // 移动停止
                                              // 移动结束也需要判断垂直或者平移
                                              // 比如水平移动结束时，要快进到指定位置，如果这里没有判断，当我们调节音量完之后，会出现屏幕跳动的bug
            switch (self.panDirection) {
                case PanDirectionHorizontalMoved: {
                    if (_player != nil && [_player isPreparedToPlay]) {
                        _sumTime = _sumTime < 0 ? 0 : _sumTime;
                        _sumTime = _sumTime > [_player duration] ? [_player duration] : _sumTime;
                        [_player setCurrentPlaybackTime:_sumTime];
                        _fastView.hidden = YES;
                    }
                        // 把sumTime滞空，不然会越加越多
                    self.sumTime = 0;
                    break;
                }
                case PanDirectionVerticalMoved: {
                        // 垂直移动结束后，把状态改为不再控制音量
                    self.isVolume = NO;
                    break;
                }
                default:
                    break;
            }
            break;
        }
        default:
            break;
    }
}

/**
 *  pan垂直移动的方法
 *
 *  @param value void
 */
- (void)verticalMoved:(CGFloat)value {
    if (value < 200 && value > -200) return;
    self.isVolume ? (self.volumeViewSlider.value -= value / 20000) : ([UIScreen mainScreen].brightness -= value / 20000);
}

/**
 *  pan水平移动的方法
 *
 *  @param value void
 */
- (void)horizontalMoved:(CGFloat)value {
    
    self.sumTime += value / 200;
    
    if (value > 0) {
        self.fastImageView.image = [UIImage imageNamed:@"fast_for"];
    } else {
        self.fastImageView.image = [UIImage imageNamed:@"fast_back"];
    }
    self.fastView.hidden = NO;
    NSTimeInterval all = [_player duration];
    NSTimeInterval next = _sumTime > all ? all : _sumTime;
    next = _sumTime < 0 ? 0 : next;
    
    NSString *timeStr = [NSString stringWithFormat:@"%@/%@", [self getTime:next], [self getTime:all]];
    self.fastTimeLabel.text = timeStr;
    CGFloat draggedValue = (CGFloat) next / (CGFloat) all;
    self.fastProgressView.progress = draggedValue;
}

- (NSString *)getTime:(NSTimeInterval)tim {
    int seconds = (int) tim;
    int second = seconds % 60;
    int hour = seconds / 60;
    NSString *sec = second < 10 ? [NSString stringWithFormat:@"0%d", second] : [NSString stringWithFormat:@"%d", second];
    
    return [NSString stringWithFormat:@"%d:%@", hour, sec];
}


@end

@implementation NELivePlayerVC (Volume)

- (void)reloadVolumeList:(NSArray *)volumeList {
    [self.detailView reloadVolumeList:volumeList];
    [self.controlView reloadVolumeList:volumeList];
    if (volumeList.count > 0) {
        self.detailView.selectedVolume = self.selectedVolume;
        self.controlView.selectedVolume = self.selectedVolume;
    }else {
        self.detailView.selectedVolume = 0;
        self.controlView.selectedVolume = 0;
    }
}

- (void)setupDetailView {
    self.detailView = [[VideoDetailView alloc] init];
    self.detailView.vc = self;
    [self.view addSubview:self.detailView];
    [self.detailView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.mas_equalTo(self.playerContainerView.mas_bottom);
        make.leading.trailing.bottom.mas_equalTo(self.view);
    }];
    self.detailView.title = _video_title;
    self.detailView.videoUrl = self.platformUrl.absoluteString;
    __weak typeof(self) weakSelf = self;
    self.detailView.chooseVolume = ^(NSIndexPath * _Nonnull indexPath, MVideoVolume * _Nonnull volumeData) {
        weakSelf.selectedVolume = indexPath.row;
        [weakSelf chooseVolume:volumeData];
        weakSelf.controlView.selectedVolume = volumeData.order - 1;
    };
    
    self.detailView.clickAdView = ^(NSDictionary * _Nonnull object) {
        NSDictionary *dic = [MethodProtocolExecutor convertParamsFromJson:object];
        [[[MethodProtocolExecutor alloc] init] invokeWithProtocol:dic[@"method"] params:dic vc:weakSelf];
    };
    
    self.detailView.clickMoreView = ^{
//        HomeQiangpianViewController *vc = [[HomeQiangpianViewController alloc] init];
        WebVC *vc = [[WebVC alloc] initWithUrlString:[NSString stringWithFormat:@"%@index.php?m=Home&c=Index&a=qiangpian&version=%@", BaseURL, APIVersion]];
        vc.disableRefreshHeader = YES;
        CustomNavigationController *navi = [[CustomNavigationController alloc] initWithRootViewController:vc];

        [weakSelf.player pause];
        [weakSelf presentViewController:navi animated:YES completion:nil];
    };
    self.detailView.clickRecommendMovie = ^(NSDictionary * _Nonnull params) {
        [weakSelf.player pause];
        
        [[[MethodProtocolExecutor alloc] init] invokeWithProtocol:params[@"method"] params:params vc:weakSelf];
    };
}

    /// 请求分集信息
- (void)requestVolumeList {
    NSString *token = [[NSUserDefaults standardUserDefaults] objectForKey:TOKEN_KEY];
    if (!token) token = @"";
    NSString *url = [NSString stringWithFormat:@"%@parse", ParseURL];
    NSDictionary *params = @{
                             @"url": _platformUrl
                             };
    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"\n😀开始获取分集数据😀"] selector:_cmd];
    
    [YQNetworking postWithUrl:url refreshRequest:NO cache:NO params:params progressBlock:nil successBlock:^(id response) {
        
        NSLog(@"response：%@", response);
        if ([response isKindOfClass:[NSDictionary class]]) {
            
            if ([response[@"code"] isEqualToString:@"error"]) {
                if ([response objectForKey:@"msg"]) {
                    [[AnalysisLogger sharedInstance] logEvent:[NSString stringWithFormat:@"获取后台自定义的解析源失败 : %@", response[@"msg"]] selector:_cmd];
                    self.detailView.updateTo = @"-";
                    self.detailView.desc = @"";
                    [self reloadVolumeList:@[]];
                }
            } else {
                if ([response objectForKey:@"data"]) {
                    self.selectedVolume = [response[@"data"][@"current"] integerValue];
                    NSString *title = response[@"data"][@"title"];
                    if (title.length) {
                        // 更新title
                        self.detailView.title = title;
                        self.controlView.fileTitle = title;
                    }
                    self.detailView.updateTo = response[@"data"][@"updatedTo"];
                    self.detailView.desc = response[@"data"][@"description"];
                    
                    NSArray *jsonArray = response[@"data"][@"data"];
                    NSMutableArray *list = [NSMutableArray array];
                    if ([jsonArray isKindOfClass:[NSArray class]]) {
                        for (NSDictionary *element in jsonArray) {
                            [list addObject:[MVideoVolume modelFromJson:element]];
                        }
                    }
                        //                    self.selectedVolume = [[SQLiteManager shareInstance] volumeWithUrl:self.entryUrl.absoluteString];
                    [self reloadVolumeList:[list copy]];
                        //                    if (self.selectedVolume < list.count) {
                        //                        [self chooseVolume:list[self.selectedVolume]];
                        //                    }
                }
            }
            
        }
    }               failBlock:^(NSError *error) {
        self.detailView.updateTo = @"-";
        self.detailView.desc = @"";
        [self reloadVolumeList:@[]];
            //        [SVProgressHUD showErrorWithStatus:error.localizedDescription];
    }];
}

@end
