//
//  NELivePlayerLoginViewController.m
//  NELivePlayerDemo
//
//  Created by BiWei on 15-10-10.
//  Copyright (c) 2015年 netease. All rights reserved.
//

#import "NELivePlayerLoginViewController.h"
#import "NELivePlayerVC.h"

#define kButtonHeight  43
#define kHorMargin     15
#define kVerMargin     64
#define kHorInternal   5
#define kVerInternal   20

@interface NELivePlayerLoginViewController () <NELivePlayerQRScanViewControllerDelegate>
{
    
}

@property (nonatomic, strong) UIButton *livestreamBtn;     //选择直播流按钮
@property (nonatomic, strong) UIButton *videoOnDemandBtn;  //选择点播流按钮
@property (nonatomic, strong) UITextField *urlPath;        //网络流地址输入框
@property (nonatomic, strong) UIButton *qrScanBtn;         //二维码扫描
@property (nonatomic, strong) UIButton *hardware;          //硬件解码按钮
@property (nonatomic, strong) UIButton *software;          //软件解码按钮
@property (nonatomic, strong) UILabel *hardwareName;       //显示硬件解码
@property (nonatomic, strong) UILabel *softwareName;       //显示软件解码
@property (nonatomic, strong) UILabel *hardwareReminder;   //硬件解码提示语
@property (nonatomic, strong) UIButton *playBtn;           //播放按钮

@property (nonatomic, strong) UISegmentedControl *media_type;
@property (nonatomic, strong) UIImageView *imageView;
@property (nonatomic, strong) UIImageView *imageViewSelected1;
@property (nonatomic, strong) UIImageView *imageViewSelected2;
@property (nonatomic, strong) UIImageView *imageViewSelected3;
@property (nonatomic, strong) UIImageView *imageViewSelected4;
@property (nonatomic, strong) UIButton *image;

@end

@implementation NELivePlayerLoginViewController
{

}

@synthesize livestreamBtn;
@synthesize videoOnDemandBtn;
@synthesize urlPath;
@synthesize qrScanBtn;
@synthesize hardware;
@synthesize software;
@synthesize hardwareName;
@synthesize softwareName;
@synthesize hardwareReminder;
@synthesize playBtn;

@synthesize media_type;
@synthesize imageView;
@synthesize imageViewSelected1;
@synthesize imageViewSelected2;
@synthesize imageViewSelected3;
@synthesize imageViewSelected4;
@synthesize image;

bool pathShowed = true;  //用于控制网络流输入框是否显示，本地文件不需要显示
NSString *mediaType = @"livestream"; //标识媒体类型，直播流还是点播流或本地文件
NSString *decodeType = @"software";  //标识解码类型，硬件解码或软件解码
int mediaTypeFlag = 1;
float width;
float height;

NELivePlayerLoginViewController *viewController;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)loadView {
    
    //用于显示的view
    self.view = [[UIView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
    self.view.backgroundColor = [UIColor whiteColor];
    
    //当前屏幕宽高
    CGFloat screenWidth  = CGRectGetWidth([UIScreen mainScreen].bounds);
    CGFloat screenHeight = CGRectGetHeight([UIScreen mainScreen].bounds);
    
    width  = screenWidth;
    height = screenHeight;
    
    //按钮宽度
    CGFloat buttonWidth = screenWidth / 2;
    
    //导航栏:播放选项
#if 1
    UILabel *label = [[UILabel alloc] initWithFrame:CGRectMake(5, 5, 120, 30)];
    label.font = [UIFont boldSystemFontOfSize:17.0]; //设置字体大小
    label.text = @"播放选项";
    label.textAlignment = NSTextAlignmentCenter; //居中显示
    self.navigationItem.titleView = label;
    //self.navigationController.navigationBar.barTintColor = [UIColor blackColor];
#else
    [self.navigationItem setTitle:@"播放选项"];
#endif
    
    //***************************** 媒体类型 ********************************//
    
    //网络直播
    self.livestreamBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.livestreamBtn.tag = 1;
    //self.livestreamBtn.frame = CGRectMake(kHorMargin, kVerMargin, buttonWidth, kButtonHeight);
    self.livestreamBtn.frame = CGRectMake(0, kVerMargin, buttonWidth, kButtonHeight);
    
    [self.livestreamBtn setBackgroundColor:[UIColor whiteColor]];
    [self.livestreamBtn setTitle:@"网络直播" forState:UIControlStateNormal];
    //self.livestreamBtn.titleLabel.textColor = [UIColor blueColor];
    self.livestreamBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    //[self.livestreamBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.livestreamBtn setTitleColor:[[UIColor alloc] initWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1.0] forState:UIControlStateNormal];
    //self.livestreamBtn.titleLabel.textColor = [[UIColor alloc] initWithRed:151.0/255 green:151.0/255 blue:151.0/255 alpha:151.0/255];
    self.livestreamBtn.backgroundColor = [UIColor clearColor];
    [self.livestreamBtn addTarget:self action:@selector(mediaTypeButtonTouched:) forControlEvents:UIControlEventTouchDown];
    
    //视频点播
    self.videoOnDemandBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.videoOnDemandBtn.tag = 2;
    //self.videoOnDemandBtn.frame = CGRectMake(2*kHorMargin+buttonWidth, kVerMargin, buttonWidth, kButtonHeight);
    self.videoOnDemandBtn.frame = CGRectMake(buttonWidth, kVerMargin, buttonWidth, kButtonHeight);
    [self.videoOnDemandBtn setTitle:@"视频点播" forState:UIControlStateNormal];
    self.videoOnDemandBtn.titleLabel.font = [UIFont boldSystemFontOfSize:14];
    //[self.videoOnDemandBtn setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
    [self.videoOnDemandBtn setTitleColor:[[UIColor alloc] initWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1.0] forState:UIControlStateNormal];
    [self.videoOnDemandBtn setBackgroundColor:[UIColor clearColor]];
    [self.videoOnDemandBtn addTarget:self action:@selector(mediaTypeButtonTouched:) forControlEvents:UIControlEventTouchDown];
    
    
    //标识选中的类型
    self.imageView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 107, screenWidth, 1)];
    [self.imageView setImage:[UIImage imageNamed:@"tab_bottom"]];
    [self.view addSubview:self.imageView];
    
    
    self.imageViewSelected1 = [[UIImageView alloc] initWithFrame:CGRectMake(0, 104, screenWidth/2, 4)];
    [self.imageViewSelected1 setImage:[UIImage imageNamed:@"tab_top"]];
    [self.view addSubview:self.imageViewSelected1];

    
    //直播和点播地址
    self.urlPath = [[UITextField alloc] initWithFrame:CGRectMake(kHorMargin, 123, screenWidth-5*kHorMargin, 38)];
    [self.urlPath setBackgroundColor:[UIColor whiteColor]];
    self.urlPath.placeholder = @"请输入直播流地址：URL";
    self.urlPath.font = [UIFont boldSystemFontOfSize:12];
    self.urlPath.textColor = [[UIColor alloc] initWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1.0];
    //[self.urlPath setTitleColor:[[UIColor alloc] initWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1.0] forState:UIControlStateNormal];
    self.urlPath.keyboardType = UIKeyboardTypeURL;
    self.urlPath.borderStyle = UITextBorderStyleRoundedRect;
    self.urlPath.autocorrectionType = UITextAutocorrectionTypeNo; //不自动纠错
    self.urlPath.clearButtonMode = UITextFieldViewModeWhileEditing;
    [self.urlPath addTarget:self action:@selector(textFieldDone:) forControlEvents:UIControlEventEditingDidEndOnExit];
    self.urlPath.autoresizingMask = UIViewAutoresizingFlexibleWidth;
    
    //二维码扫描
    self.qrScanBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    [self.qrScanBtn setImage:[UIImage imageNamed:@"btn_qr_scan"] forState:UIControlStateNormal];
    self.qrScanBtn.frame = CGRectMake(screenWidth-49, 123, 38, 38);
    [self.qrScanBtn addTarget:self action:@selector(onClickQRScan:) forControlEvents:UIControlEventTouchUpInside];
    
    
    //***************************** 解码类型 ********************************//
    
    //软件解码按钮
    self.software = [UIButton buttonWithType:UIButtonTypeCustom];
    self.software.frame = CGRectMake(screenWidth/2-110, 201, 22, 22);
    [self.software setImage:[UIImage imageNamed:@"btn_player_selected"] forState:UIControlStateNormal];
    [self.software addTarget:self action:@selector(setSoftwareButtonStyle:) forControlEvents:UIControlEventTouchUpInside];
    
    //硬件解码按钮
    self.hardware = [UIButton buttonWithType:UIButtonTypeCustom];
    self.hardware.frame = CGRectMake(screenWidth/2+32, 201, 22, 22);
    [self.hardware setImage:[UIImage imageNamed:@"btn_player_unselected"] forState:UIControlStateNormal];
    [self.hardware addTarget:self action:@selector(setHardwareButtonStyle:) forControlEvents:UIControlEventTouchUpInside];
    
    //软件解码名称
    self.softwareName = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth/2-88, 201, 56, 22)];
    self.softwareName.text = @"软件解码";
    self.softwareName.textColor = [[UIColor alloc] initWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1.0];
    self.softwareName.font = [UIFont boldSystemFontOfSize:14];
    
    //硬件解码名称
    self.hardwareName = [[UILabel alloc] initWithFrame:CGRectMake(screenWidth/2+54, 201, 56, 22)];
    self.hardwareName.text = @"硬件解码";
    self.hardwareName.textColor = [[UIColor alloc] initWithRed:51.0/255 green:51.0/255 blue:51.0/255 alpha:1.0];
    self.hardwareName.font = [UIFont boldSystemFontOfSize:14];

    //硬件解码提示语
    self.hardwareReminder = [[UILabel alloc] initWithFrame:CGRectMake(30, screenHeight - 39, screenWidth - 60, 14)];
    self.hardwareReminder.text = @"硬件解码在IOS 8.0以上才支持";
    self.hardwareReminder.textAlignment = NSTextAlignmentCenter;
    self.hardwareReminder.numberOfLines = 0;
    self.hardwareReminder.textColor = [UIColor grayColor];
    
    
    
    //***************************** 开始播放 ********************************//
    
    //播放按钮
    self.playBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    self.playBtn.tag = 5;
    self.playBtn.frame = CGRectMake(kHorMargin, 241, screenWidth - 2*kHorMargin, 40);
    [self.playBtn setBackgroundImage:[UIImage imageNamed:@"btn_player_start_play"] forState:UIControlStateNormal];
    [self.playBtn setTitle:@"播 放" forState:UIControlStateNormal];
    self.playBtn.titleLabel.font = [UIFont systemFontOfSize:14.0];
    self.playBtn.titleLabel.textColor = [[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:1.0];

    [self.playBtn addTarget:self action:@selector(playButtonPressed:) forControlEvents:UIControlEventTouchUpInside];
    

    //***************************** 所有控件全部添加到view中 ********************************//
    
    [self.view addSubview:self.livestreamBtn];
    [self.view addSubview:self.videoOnDemandBtn];
    [self.view addSubview:self.urlPath];
    [self.view addSubview:self.qrScanBtn];
    [self.view addSubview:self.hardware];
    [self.view addSubview:self.software];
    [self.view addSubview:self.hardwareName];
    [self.view addSubview:self.softwareName];
    [self.view addSubview:self.hardwareReminder];
    [self.view addSubview:self.playBtn];
}


- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    //NSLog(@"------------------------------------");
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    //NSLog(@"----------------shouldAutorotateToInterfaceOrientation--------------------");
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}

- (NSUInteger)supportedInterfaceOrientations
{
    //NSLog(@"----------------supportedInterfaceOrientations--------------------");
    return UIInterfaceOrientationMaskPortrait;
}

- (BOOL)shouldAutorotate
{
    //NSLog(@"------------------shouldAutorotate------------------");
    return NO;
}

//- (NSUInteger)supportedInterfaceOrientations
//{
//    return [self.view.]
//}

- (UIInterfaceOrientation)preferredInterfaceOrientationForPresentation {
    return UIInterfaceOrientationPortrait;
}


#pragma mark - Buttons methods
- (void) mediaTypeButtonTouched:(id)sender { //媒体类型按钮的响应函数
    UIButton *aButton = (UIButton *)sender; //这时sender表示的是当前按下的button
    
    switch (aButton.tag) { //根据tag来获取哪个按钮被按下
        case 1:
            if (!pathShowed) { //直播需要显示url输入框
                //[self.view addSubview:self.urlPath];
                self.urlPath.hidden = NO;
                pathShowed = true; //标识网络流输入框的显示状态
            }
            self.urlPath.hidden = NO;
            self.imageViewSelected1.frame = CGRectMake(0, 104, width/2, 4);
            self.urlPath.placeholder = @"请输入直播流地址：URL";
            [self decodeTypePresent:YES]; //直播解码类型要显示
            mediaType = @"livestream";
            self.software.frame = CGRectMake(width/2-110, 201, 22, 22);
            self.hardware.frame = CGRectMake(width/2+32, 201, 22, 22);
            self.softwareName.frame = CGRectMake(width/2-88, 201, 56, 22);
            self.hardwareName.frame = CGRectMake(width/2+54, 201, 56, 22);
            break;
        case 2:
            if (!pathShowed) { //点播需要显示url输入框
                //[self.view addSubview:self.urlPath];
                self.urlPath.hidden = NO;
                pathShowed = true; //标识网络流输入框的显示状态
            }
            self.urlPath.hidden = NO;
            self.imageViewSelected1.frame = CGRectMake(width/2, 104, width/2, 4);
            self.urlPath.placeholder = @"请输入点播流地址：URL";
            [self decodeTypePresent:YES]; //点播解码类型要显示
            mediaType = @"videoOnDemand";
            self.software.frame = CGRectMake(width/2-110, 201, 22, 22);
            self.hardware.frame = CGRectMake(width/2+32, 201, 22, 22);
            self.softwareName.frame = CGRectMake(width/2-88, 201, 56, 22);
            self.hardwareName.frame = CGRectMake(width/2+54, 201, 56, 22);
            break;
        default:
            break;
    }
}


- (void)setHardwareButtonStyle:(id)sender {
    NSLog(@"hardware selected!");
    decodeType = @"hardware";
    [self.hardware setSelected:YES];
    [self.software setSelected:NO];
    [self.hardware setImage:[UIImage imageNamed:@"btn_player_selected"] forState:UIControlStateSelected];
    [self.software setImage:[UIImage imageNamed:@"btn_player_unselected"] forState:UIControlStateNormal];
}

- (void)setSoftwareButtonStyle:(id)sender {
    NSLog(@"software selected!");
    decodeType = @"software";
    [self.hardware setSelected:NO];
    [self.software setSelected:YES];
    [self.software setImage:[UIImage imageNamed:@"btn_player_selected"] forState:UIControlStateSelected];
    [self.hardware setImage:[UIImage imageNamed:@"btn_player_unselected"] forState:UIControlStateNormal];
}

- (void)decodeTypePresent:(BOOL) isPresent {
    self.hardware.hidden         = !isPresent;
    self.hardwareName.hidden     = !isPresent;
    self.hardwareReminder.hidden = !isPresent;
    self.software.hidden         = !isPresent;
    self.softwareName.hidden     = !isPresent;
    self.playBtn.hidden          = !isPresent;
}

- (void)playButtonPressed:(id)sender {
    NSLog(@"play button pressed!");
    UIAlertView *alert = NULL; //定义一个消息提示框
    NSURL *url = NULL; //待播放的文件路径
    if ([mediaType isEqualToString:@"livestream"] || [mediaType isEqualToString:@"videoOnDemand"]) { //直播流或点播流
        if ([self.urlPath.text length] == 0) {//输入框未输入时提示
            if ([mediaType isEqualToString:@"livestream"]) {
                alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入直播流地址" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            }
            else if([mediaType isEqualToString:@"videoOnDemand"]) {
                alert = [[UIAlertView alloc] initWithTitle:@"提示" message:@"请输入点播流地址" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil];
            }
            
            [alert show];
            return;
        }
    
        url = [[NSURL alloc] initWithString:self.urlPath.text];
    }
    
    NSMutableArray *decodeParm = [[NSMutableArray alloc] init];
    [decodeParm addObject:decodeType];
    [decodeParm addObject:mediaType];
    
//    NELivePlayerViewController *nelpViewController = [[NELivePlayerViewController alloc] initWithURL:url andDecodeParm:decodeParm];
//    [self presentViewController:nelpViewController animated:YES completion:nil];
    
    NELivePlayerVC *player = [[NELivePlayerVC alloc] initWithURL:url andDecodeParm:decodeParm];
    [self presentViewController:player animated:YES completion:nil];
}

- (void)onClickQRScan:(id)sender {
    NSLog(@"QRScan starting!");
    NELivePlayerQRScanViewController *qrScanner = [[NELivePlayerQRScanViewController alloc] init];
    qrScanner.delegate = self;
    [self.navigationController pushViewController:qrScanner animated:YES];
}

- (void)NELivePlayerQRScanViewController:(NELivePlayerQRScanViewController *)qrScanner didFinishScanner:(NSString *)string {
    self.urlPath.text = string;
}


#pragma mark - textField method
- (void)textFieldDone:(UITextField *)textField {
    [textField resignFirstResponder];
}



@end
