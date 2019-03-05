//
//  NELivePlayerQRScanViewController.h
//  NELivePlayerDemo
//
//  Created by BiWei on 16/10/10.
//  Copyright © 2016年 netease. All rights reserved.
//

#import <UIKit/UIKit.h>

@class NELivePlayerQRScanViewController;
@protocol NELivePlayerQRScanViewControllerDelegate <NSObject>

- (void)NELivePlayerQRScanViewController:(NELivePlayerQRScanViewController *)qrScanner didFinishScanner:(NSString *)string;

@end


@interface NELivePlayerQRScanViewController : UIViewController

@property (nonatomic, assign) id<NELivePlayerQRScanViewControllerDelegate> delegate;

@end
