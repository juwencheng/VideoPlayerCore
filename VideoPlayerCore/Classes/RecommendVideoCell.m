//
//  RecommendVideoCell.m
//  Thunder
//
//  Created by 鞠汶成 on 2019/1/22.
//  Copyright © 2019 Lance Wu. All rights reserved.
//

#import "RecommendVideoCell.h"
#import "UIImageView+WebCache.h"
@interface RecommendVideoCell ()

@property (weak, nonatomic) IBOutlet UILabel *titleLabel;
@property (weak, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (weak, nonatomic) IBOutlet UIImageView *coverImageView;

@property (weak, nonatomic) IBOutlet UIImageView *typeImageView;

@end

@implementation RecommendVideoCell

- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (void)setModel:(NSDictionary *)model {
    _model = model;
    [self.coverImageView sd_setImageWithURL:[NSURL URLWithString:[NSString stringWithFormat:@"%@%@", BaseURL, model[@"pic"]]]];
    NSString *title = model[@"title"];
    title = title.length > 0 ? title : @"";
    self.titleLabel.text = title;
    
    NSString *subtitle = model[@"subtitle"];
    subtitle = subtitle.length > 0 ? subtitle : @"";
    self.subtitleLabel.text = subtitle;
    self.typeImageView.image = [UIImage imageNamed:model[@"type"]];
}

@end
