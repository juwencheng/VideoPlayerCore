//
//  VideoVolumeCell.h
//  Thunder
//
//  Created by 鞠汶成 on 2018/12/22.
//  Copyright © 2018 Lance Wu. All rights reserved.
//

#import <UIKit/UIKit.h>
@class MVideoVolume;
NS_ASSUME_NONNULL_BEGIN

@interface VideoVolumeCell : UICollectionViewCell
@property (nonatomic, copy) NSString *volumeText;
@property (nonatomic, strong) MVideoVolume *volume;
@end

@interface OverlayVideoVolumeCell : VideoVolumeCell

@end

NS_ASSUME_NONNULL_END
