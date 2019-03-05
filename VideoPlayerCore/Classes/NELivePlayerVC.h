//
//  NELivePlayerVC.h
//  NELivePlayerDemo
//
//  Created by Netease on 2017/11/15.
//  Copyright © 2017年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>
#define MAS_SHORTHAND
#define MAS_SHORTHAND_GLOBALS
// 颜色值RGB
#define RGBA(r,g,b,a)                       [UIColor colorWithRed:r/255.0f green:g/255.0f blue:b/255.0f alpha:a]

@class GADInterstitial;
@interface NELivePlayerVC : UIViewController

@property (nonatomic, strong) NSString *isLoadLine; // 抢片的时候，设置了isLoadLine 为isLoad
@property (nonatomic, strong) GADInterstitial *interstitial;
- (instancetype)initWithURL:(NSURL *)url andDecodeParm:(NSMutableArray *)decodeParm;

- (void)changeURL:(NSURL *)url decodeParam:(NSMutableArray *)decodeParam;

@end
