//
//  NELivePlayerVC+Admob.m
//  Thunder
//
//  Created by 鞠汶成 on 2019/3/4.
//  Copyright © 2019 Lance Wu. All rights reserved.
//

#import "NELivePlayerVC+Admob.h"
#import "FirebaseAdmobUtility.h"
@implementation NELivePlayerVC (Admob)
- (void)requestChaye {
    self.interstitial = [self createAndLoadInterstitial];
}

- (GADInterstitial *)createAndLoadInterstitial {

    NSString *unitId = [FirebaseAdmobUtility unitIdWithModule:@"play_video_page_chaye"];
    if (unitId.length > 0) {
        GADInterstitial *interstitial =
        [[GADInterstitial alloc] initWithAdUnitID:unitId];
        interstitial.delegate = self;
        [interstitial loadRequest:[GADRequest request]];
        return interstitial;
    }
    return nil;
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)interstitial {
    self.interstitial = [self createAndLoadInterstitial];
}

- (void)presentChaye {
    if (self.interstitial && self.interstitial.isReady) {
        [self.interstitial presentFromRootViewController:self];
    }
}
@end
