//
//  LoadingView.h
//  Application
//
//  Created by 强邹 on 2017/11/29.
//  Copyright © 2017年 Lance Wu. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
@interface LoadingView : NSObject

@property (nonatomic, strong) UIView *view;
@property (nonatomic, strong) UILabel *loading_tv;
@property (nonatomic, strong) UIActivityIndicatorView *activityIndicator;

- (instancetype)initWithTitle:(NSString *)title;
- (instancetype)initWithWebViewTitle:(NSString *)title;
- (void)setTitle:(NSString *)title;

@end
