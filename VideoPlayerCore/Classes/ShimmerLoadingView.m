//
//  ShimmerLoadingView.m
//  Thunder
//
//  Created by 鞠汶成 on 2019/1/16.
//  Copyright © 2019 Lance Wu. All rights reserved.
//

#import "ShimmerLoadingView.h"
#import "View+MASAdditions.h"

@interface ShimmerLoadingView ()

@property (nonatomic, strong) UIImageView *bgImageView;

@end

@implementation ShimmerLoadingView


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
    [self addSubview:self.bgImageView];
    _isAnimating = YES;
    self.backgroundColor = [UIColor blackColor];
    [self.bgImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(self);
    }];
    
}

- (void)layoutSubviews {
    [super layoutSubviews];
    if (_isAnimating) {
        [self startAnimation];
    }else {
        [self stopAnimations];
    }
}

- (void)setIsAnimating:(BOOL)isAnimating {
    _isAnimating = isAnimating;
    [self setNeedsLayout];
    [self layoutSubviews];
}

- (void)stopAnimations {
    [self.bgImageView.layer removeAllAnimations];
}

- (void)startAnimation {
    CABasicAnimation *animation =
    [CABasicAnimation animationWithKeyPath:@"opacity"];
    
    [animation setRepeatCount:HUGE_VALF];
    [animation setDuration:1.5];
    [animation setAutoreverses:YES];
    [animation setFromValue:@1];
    [animation setToValue:@(0.5)];
    animation.fillMode = kCAFillModeBoth;
    animation.timingFunction = [CAMediaTimingFunction functionWithName:kCAMediaTimingFunctionEaseInEaseOut];
    [[self.bgImageView layer] addAnimation:animation forKey:@"opacity"];
}

- (UIImageView *)bgImageView {
    if (!_bgImageView) {
        _bgImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"waiting_bg.jpg"]];
    }
    return _bgImageView;
}

@end
