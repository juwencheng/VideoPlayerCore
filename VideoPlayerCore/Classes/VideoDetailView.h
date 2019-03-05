//
//  VideoDetailView.h
//  Thunder
//
//  Created by 鞠汶成 on 2018/12/22.
//  Copyright © 2018 Lance Wu. All rights reserved.
//

#import "XibView.h"
@class MVideoVolume;
NS_ASSUME_NONNULL_BEGIN

@interface VideoDetailView : XibView

- (void)reloadVolumeList:(NSArray *)volumeList;

@property (nonatomic, copy) NSString *desc;
@property (nonatomic, copy) NSString *videoUrl;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger selectedVolume;
@property (nonatomic, copy) NSString *updateTo;
@property (nonatomic, weak) UIViewController *vc;
@property (nonatomic, copy) void (^chooseVolume)(NSIndexPath *indexPath, MVideoVolume *volumeData);
@property (nonatomic, copy) void (^clickAdView)(NSDictionary *object);
@property (nonatomic, copy) void (^clickMoreView)(void);
@property (nonatomic, copy) void (^clickRecommendMovie)(NSDictionary *params);
@end

NS_ASSUME_NONNULL_END
