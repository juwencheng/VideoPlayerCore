//
//  VideoVolumeCell.m
//  Thunder
//
//  Created by 鞠汶成 on 2018/12/22.
//  Copyright © 2018 Lance Wu. All rights reserved.
//

#import "VideoVolumeCell.h"
#import "Masonry.h"
#import "MVideoVolume.h"
@interface VideoVolumeCell()
@property (strong, nonatomic) UILabel *volumeLabel;
@property (strong, nonatomic) UILabel *vipLabel;
@end

@implementation VideoVolumeCell

- (instancetype)initWithCoder:(NSCoder *)aDecoder {
    self = [super initWithCoder:aDecoder];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (instancetype)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if (self) {
        [self commonInit];
    }
    return self;
}

- (void)commonInit {
    [self addSubview:self.volumeLabel];
    [self.volumeLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
    self.layer.cornerRadius = 5;
    self.clipsToBounds = YES;
    self.volumeLabel.backgroundColor = Color(@"f2eeee");
    self.volumeLabel.textColor = Color(@"333333");
    
    [self addSubview:self.vipLabel];
    [self.vipLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.trailing.mas_equalTo(self);
        make.width.mas_equalTo(self).multipliedBy(0.4);
        make.height.mas_equalTo(self).multipliedBy(0.33);
    }];
    self.vipLabel.layer.cornerRadius = 5;
    self.vipLabel.clipsToBounds = YES;
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
    if (selected) {
        self.volumeLabel.backgroundColor = Color(@"32293a");
        self.volumeLabel.textColor = [UIColor whiteColor];
    }else {
        self.volumeLabel.backgroundColor = Color(@"f2eeee");
        self.volumeLabel.textColor = Color(@"333333");
    }
}

- (void)setVolumeText:(NSString *)volumeText {
    _volumeText = volumeText;
    self.volumeLabel.text = volumeText;
}

- (void)setVolume:(MVideoVolume *)volume {
    _volume = volume;
    switch (volume.type) {
        case 0:
            self.vipLabel.hidden = YES;
            break;
        case 1:
            self.vipLabel.text = @"预告";
            self.vipLabel.hidden = NO;
            self.vipLabel.backgroundColor = [UIColor colorWithRed:0.13 green:0.67 blue:0.74 alpha:1.00];
            break;
        case 2:
            self.vipLabel.text = @"会员";
            self.vipLabel.hidden = NO;
            self.vipLabel.backgroundColor = [UIColor colorWithRed:0.98 green:0.40 blue:0.13 alpha:1.00];
            break;
        default:
            break;
    }
}

- (UILabel *)volumeLabel {
    if (!_volumeLabel) {
        _volumeLabel = [UILabel new];
        _volumeLabel.textAlignment = NSTextAlignmentCenter;
        _volumeLabel.backgroundColor = [UIColor colorWithRed:0.88 green:0.88 blue:0.89 alpha:1.00];
        _volumeLabel.textColor = [UIColor colorWithRed:0.22 green:0.22 blue:0.24 alpha:1.00];
    }
    return _volumeLabel;
}

- (UILabel *)vipLabel {
    if (!_vipLabel) {
        _vipLabel = [UILabel new];
        _vipLabel.textAlignment = NSTextAlignmentCenter;
        _vipLabel.font = [UIFont fontWithName:@"Helvetica-Oblique" size:10];
        _vipLabel.backgroundColor = [UIColor clearColor];
        _vipLabel.textColor = [UIColor whiteColor];
    }
    return _vipLabel;
}

@end

@implementation OverlayVideoVolumeCell

- (void)commonInit {
    [super commonInit];
//    self.layer.borderWidth = 0;
//    self.layer.borderColor = [UIColor clearColor].CGColor;
//    self.backgroundColor = [UIColor clearColor];
//    self.volumeLabel.backgroundColor = [UIColor blackColor];
//    self.volumeLabel.textColor = [UIColor whiteColor];
}

- (void)setSelected:(BOOL)selected {
    [super setSelected:selected];
//    if (selected) {
//        self.volumeLabel.backgroundColor = [UIColor redColor];
//        self.volumeLabel.textColor = [UIColor whiteColor];
//    }else {
//        self.volumeLabel.backgroundColor = [UIColor blackColor];
//        self.volumeLabel.textColor = [UIColor whiteColor];
//    }
}

@end
