//
//  VideoDetailView.m
//  Thunder
//
//  Created by 鞠汶成 on 2018/12/22.
//  Copyright © 2018 Lance Wu. All rights reserved.
//

#import "VideoDetailView.h"
#import "VideoVolumeCell.h"
#import "MVideoVolume.h"
#import "UIImageView+WebCache.h"
#import "RecommendVideoCell.h"
#import "MethodProtocolExecutor.h"
#import "VideoRegexTool.h"
#import "FirebaseAdmobUtility.h"

@import GoogleMobileAds;

@interface VideoDetailView()<UICollectionViewDelegate, UICollectionViewDataSource, UITableViewDelegate, UITableViewDataSource>

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView;
@property (nonatomic, strong) NSArray<MVideoVolume *> *volumeList;
@property (weak, nonatomic) IBOutlet UILabel *updateLabel;
@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (nonatomic, strong) NSDictionary *adObject;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextView;

@property (weak, nonatomic) IBOutlet UIImageView *adImageView;
@property (weak, nonatomic) IBOutlet UIView *emptyTipView;
@property (weak, nonatomic) IBOutlet UIButton *downloadBtn;
@property (weak, nonatomic) IBOutlet UIView *adContainerView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *collectionViewHeightConst;
@property (weak, nonatomic) IBOutlet UITableView *tableView;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *tableViewHeightConst;

@property (weak, nonatomic) IBOutlet UIButton *shareBtn;
@property (nonatomic, strong) NSMutableArray *recommendData;

@property (weak, nonatomic) IBOutlet UICollectionView *collectionView1;
@property (strong, nonatomic) IBOutlet UIView *volumnView;

@property (weak, nonatomic) IBOutlet UITextView *descTextView1;
@property (strong, nonatomic) IBOutlet UIView *descView;


@property (nonatomic, strong) GADBannerView *bannerView;
@property (nonatomic, copy) NSString *unitId;
@end

@interface VideoDetailView(adMob)<GADBannerViewDelegate>
- (void)addBannerView;
@end

@implementation VideoDetailView

- (void)commonInit {
    [super commonInit];
    // VideoVolumeCell
    UICollectionViewFlowLayout *layout = (UICollectionViewFlowLayout *)self.collectionView.collectionViewLayout;
    UICollectionViewFlowLayout *layout1 = (UICollectionViewFlowLayout *)self.collectionView1.collectionViewLayout;
    CGFloat width = ([UIScreen mainScreen].bounds.size.width - 50 - 10 - 10) / 6.0;
    CGFloat width1 = ([UIScreen mainScreen].bounds.size.width - 50 - 16 - 16) / 6.0;
    layout.itemSize = CGSizeMake(width, width);
    layout1.itemSize = CGSizeMake(width, width);
    layout.sectionInset = UIEdgeInsetsMake(4, 0, 4, 0);
    self.collectionViewHeightConst.constant = width + 8;
    [self.collectionView registerClass:[VideoVolumeCell class] forCellWithReuseIdentifier:@"VideoVolumeCell"];
    [self.collectionView1 registerClass:[VideoVolumeCell class] forCellWithReuseIdentifier:@"VideoVolumeCell"];

    self.shareBtn.layer.cornerRadius = 15;
//    self.shareBtn.layer.borderWidth = 1;
//    self.shareBtn.layer.borderColor = Color(@"999999").CGColor;
    self.shareBtn.clipsToBounds = YES;
    self.adContainerView.layer.shadowColor = [UIColor whiteColor].CGColor;
    self.adContainerView.layer.shadowOffset = CGSizeMake(0, -10);
    self.adContainerView.layer.shadowRadius = 10;
    self.adContainerView.layer.shadowOpacity = 1;
    
    [self.tableView registerNib:[UINib nibWithNibName:@"RecommendVideoCell" bundle:nil] forCellReuseIdentifier:@"RecommendVideoCell"];
    self.tableView.contentInset = UIEdgeInsetsMake(0, 0, 30, 0);
    self.tableViewHeightConst.constant = 0;
    [self requestRecommendData];
    self.shareBtn.hidden = [VideoRegexTool shareUrl].length == 0;
    [self addSubview:self.volumnView];
    [self addSubview:self.descView];
}

- (void)reloadVolumeList:(NSArray *)data {
    self.volumeList = data;
    [self.collectionView reloadData];
    [self.collectionView1 reloadData];
    if (data.count == 0) {
        if (self.desc.length > 0) {
            self.descriptionTextView.text = [NSString stringWithFormat:@"剧情简介：\n%@", self.desc];
            [self bringSubviewToFront:self.descriptionTextView];
            self.descriptionTextView.hidden = NO;
            self.emptyTipView.hidden = YES;

        }else {
            self.descriptionTextView.hidden = YES;
            self.emptyTipView.hidden = NO;
        }
    }else if (data.count <= 1){
        if (self.desc.length > 0) {
            self.descriptionTextView.text = [NSString stringWithFormat:@"剧情简介：\n%@", self.desc];
            [self bringSubviewToFront:self.descriptionTextView];
            self.descriptionTextView.hidden = NO;
            self.emptyTipView.hidden = YES;
        }else {
            self.descriptionTextView.hidden = YES;
            self.emptyTipView.hidden = YES;
        }
    }else {
        self.descriptionTextView.hidden = YES;
        self.emptyTipView.hidden = YES;
    }
}

- (void)setSelectedVolume:(NSInteger)selectedVolume {
    _selectedVolume = selectedVolume;
    if (selectedVolume < self.volumeList.count) {        
        [self.collectionView selectItemAtIndexPath:[NSIndexPath indexPathForRow:selectedVolume inSection:0] animated:NO scrollPosition:UICollectionViewScrollPositionRight];
    }
}

- (void)setUpdateTo:(NSString *)updateTo {
    _updateTo = updateTo;
    [self.downloadBtn setTitle:[NSString stringWithFormat:@"更新至%@集 >", updateTo] forState:UIControlStateNormal];
}

- (void)setTitle:(NSString *)title {
    _title = title;
    self.titleLabel.text = title;
}

- (void)setVideoUrl:(NSString *)videoUrl {
    _videoUrl = videoUrl;
    NSURL *videoURL = [NSURL URLWithString:videoUrl];
    NSString *url = [NSString stringWithFormat:@"%@index.php?m=Home&c=Index&a=vedio_adv&type=%@&version=%@", BaseURL, videoURL.host, APIVersion];
    [YQNetworking getWithUrl:url refreshRequest:YES cache:NO params:nil progressBlock:nil successBlock:^(id response) {
        NSLog(@"response：%@", response);
        if ([response isKindOfClass:[NSDictionary class]]) {
            if (![response[@"code"] isEqualToString:@"error"]) {
                self.adObject = response[@"data"];
            }
        }
    }               failBlock:^(NSError *error) {
//        [SVProgressHUD showErrorWithStatus:@"网络连接中断"];
    }];
}

- (void)requestRecommendData {
    NSString *url = [NSString stringWithFormat:@"%@index.php?m=Home&c=Index&a=video_recommend&version=%@", BaseURL, APIVersion];
    [YQNetworking getWithUrl:url refreshRequest:YES cache:NO params:nil progressBlock:nil successBlock:^(id response) {
        NSLog(@"response：%@", response);
        if ([response isKindOfClass:[NSDictionary class]]) {
            if (![response[@"code"] isEqualToString:@"error"]) {
                NSArray *jsonData = response[@"data"];
                if ([jsonData isKindOfClass:[NSArray class]]) {
                    [self.recommendData addObjectsFromArray:jsonData];
                }
                [self reloadTableView];
            }
        }
        
    }               failBlock:^(NSError *error) {
            //        [SVProgressHUD showErrorWithStatus:@"网络连接中断"];
    }];
}

- (void)reloadTableView {
    self.tableViewHeightConst.constant = self.recommendData.count * 90 + 0.1 * self.recommendData.count + self.tableView.contentInset.bottom;
    [self.tableView reloadData];
}

- (IBAction)viewMore:(id)sender {
    if (self.clickMoreView) {
        self.clickMoreView();
    }
}

#pragma mark - UICollectionViewDelegate & UICollectionViewDataSource
- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.volumeList.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    VideoVolumeCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"VideoVolumeCell" forIndexPath:indexPath];
    cell.volumeText = [NSString stringWithFormat:@"%ld", self.volumeList[indexPath.row].order];
    _selectedVolume = self.volumeList[indexPath.row].order;
    cell.volume = self.volumeList[indexPath.row];
    return cell;
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.chooseVolume) {
        self.chooseVolume(indexPath, self.volumeList[indexPath.row]);
    }
    if (self.collectionView1 == collectionView) {
        [self.collectionView selectItemAtIndexPath:indexPath animated:YES scrollPosition:UICollectionViewScrollPositionCenteredHorizontally];
        [self hideVolumnView:nil];
    }else {
        [self.collectionView1 selectItemAtIndexPath:indexPath animated:NO scrollPosition:UICollectionViewScrollPositionBottom];
    }
}

- (IBAction)tapAdImageView:(id)sender {
    if (self.clickAdView && self.adObject) {
        self.clickAdView(self.adObject);
    }
}

- (void)setAdObject:(NSDictionary *)adObject {
    _adObject = adObject;
    NSString *imagePath = adObject[@"realpic"];
    if (imagePath.length) {
        [self.adImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@", imagePath]] placeholderImage:[UIImage new]];
    }
}

- (IBAction)share:(id)sender {
    if (self.clickRecommendMovie) {
        if ([VideoRegexTool shareUrl].length > 0) {
            NSDictionary *params = @{
                                     @"type": @1,
                                     @"title": @"闪电影视APP",
                                     @"subtitle": @"闪电影视，轻松看全网，享受好时光！",
                                     @"imgUrl": [UIImage imageNamed:@"Icon-60"],
                                     @"url": [VideoRegexTool shareUrl],
                                     @"method": @"v1.share"
                                     };
            self.clickRecommendMovie(params);
        }
        
    }
}

- (void)setVc:(UIViewController *)vc {
    _vc = vc;
    self.unitId = [FirebaseAdmobUtility unitIdWithModule:@"play_video_page_banner"];
    if (self.unitId.length > 0) {
        [self requestADMobBanner];
    }
}

#pragma mark - uitableview datasource & delegate
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
    return self.recommendData.count;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return 0.1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForFooterInSection:(NSInteger)section {
    return 10;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return 80;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    RecommendVideoCell *cell = [self.tableView dequeueReusableCellWithIdentifier:@"RecommendVideoCell"];
    cell.model = self.recommendData[indexPath.section];
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    if (self.clickRecommendMovie) {
        NSDictionary *element = self.recommendData[indexPath.section];
        NSDictionary *json = [MethodProtocolExecutor convertParamsFromJson:element];
        if (json != nil) {
            self.clickRecommendMovie(json);
        }
    }
}


- (IBAction)showVolumnView:(id)sender {
    if (self.volumeList.count == 0) {
        return;
    }
    CGRect frame = self.bounds;
    frame.origin.y = frame.size.height;
    self.volumnView.frame = frame;
    frame.origin.y = 0;
    self.volumnView.hidden = NO;
    [self bringSubviewToFront:self.volumnView];
    [UIView animateWithDuration:0.25 animations:^{
        self.volumnView.frame = frame;
        [self.collectionView1 reloadData];
    }];
}

- (IBAction)hideVolumnView:(id)sender {
    CGRect frame = self.bounds;
    frame.origin.y = frame.size.height;
    self.volumnView.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.volumnView.frame = frame;
        [self sendSubviewToBack:self.volumnView];
    }];
}

- (IBAction)showDescView:(id)sender {
    if (self.desc.length == 0) {
        [SVProgressHUD showInfoWithStatus:@"暂无简介"];
        return;
    }
    CGRect frame = self.bounds;
    frame.origin.y = frame.size.height;
    self.descView.frame = frame;
    frame.origin.y = 0;
    self.descView.hidden = NO;
    [self bringSubviewToFront:self.descView];
    self.descTextView1.text = self.desc;
    NSMutableParagraphStyle *style = [[NSMutableParagraphStyle alloc] init];
    style.lineSpacing = 10;
    self.descTextView1.attributedText = [[NSAttributedString alloc] initWithString:self.desc attributes:@{NSParagraphStyleAttributeName: style, NSFontAttributeName: [UIFont systemFontOfSize:15], NSForegroundColorAttributeName: [UIColor lightGrayColor]}];
    [UIView animateWithDuration:0.25 animations:^{
        self.descView.frame = frame;
    }];
}

- (IBAction)hideDescView:(id)sender {
    CGRect frame = self.bounds;
    frame.origin.y = frame.size.height;
    self.descView.hidden = YES;
    [UIView animateWithDuration:0.25 animations:^{
        self.descView.frame = frame;
        [self sendSubviewToBack:self.descView];
    }];
}

- (void)requestADMobBanner {
    self.bannerView.adUnitID = self.unitId;
    self.bannerView.rootViewController = self.vc;
    self.bannerView.delegate = self;
    [self.bannerView loadRequest:[GADRequest request]];
}

- (NSMutableArray *)recommendData {
    if (!_recommendData) {
        _recommendData = [NSMutableArray array];
    }
    return _recommendData;
}

- (GADBannerView *)bannerView {
    if (!_bannerView) {
        _bannerView = [[GADBannerView alloc]
         initWithAdSize:kGADAdSizeLargeBanner];
    }
    return _bannerView;
}

@end


@implementation VideoDetailView (adMob)

- (void)addBannerView {
    if (![self.adContainerView.subviews containsObject:self.bannerView]) {
        [self.adContainerView addSubview:self.bannerView];
        self.bannerView.translatesAutoresizingMaskIntoConstraints = NO;
        [self.adContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[bannerView]|" options:0 metrics:nil views:@{@"bannerView": self.bannerView}]];
        [self.adContainerView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[bannerView]|" options:0 metrics:nil views:@{@"bannerView": self.bannerView}]];
    }
}
    /// Tells the delegate an ad request loaded an ad.
- (void)adViewDidReceiveAd:(GADBannerView *)adView {
    [self addBannerView];
}

    /// Tells the delegate an ad request failed.
- (void)adView:(GADBannerView *)adView
didFailToReceiveAdWithError:(GADRequestError *)error {
    if ([self.adContainerView.subviews containsObject:self.bannerView]) {
        [self.bannerView removeFromSuperview];
    }
    NSLog(@"adView:didFailToReceiveAdWithError: %@", [error localizedDescription]);
}

    /// Tells the delegate that a full-screen view will be presented in response
    /// to the user clicking on an ad.
- (void)adViewWillPresentScreen:(GADBannerView *)adView {
    NSLog(@"adViewWillPresentScreen");
}

    /// Tells the delegate that the full-screen view will be dismissed.
- (void)adViewWillDismissScreen:(GADBannerView *)adView {
    NSLog(@"adViewWillDismissScreen");
}

    /// Tells the delegate that the full-screen view has been dismissed.
- (void)adViewDidDismissScreen:(GADBannerView *)adView {
    NSLog(@"adViewDidDismissScreen");
}

    /// Tells the delegate that a user click will open another app (such as
    /// the App Store), backgrounding the current app.
- (void)adViewWillLeaveApplication:(GADBannerView *)adView {
    NSLog(@"adViewWillLeaveApplication");
}

@end
