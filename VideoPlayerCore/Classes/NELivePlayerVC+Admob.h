//
//  NELivePlayerVC+Admob.h
//  Thunder
//
//  Created by 鞠汶成 on 2019/3/4.
//  Copyright © 2019 Lance Wu. All rights reserved.
//

#import "NELivePlayerVC.h"
@import GoogleMobileAds;

NS_ASSUME_NONNULL_BEGIN

@interface NELivePlayerVC (Admob)<GADInterstitialDelegate>
- (void)requestChaye;
- (void)presentChaye;
@end

NS_ASSUME_NONNULL_END
