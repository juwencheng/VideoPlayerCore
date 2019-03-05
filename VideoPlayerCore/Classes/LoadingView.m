//
//  LoadingView.m
//  Application
//
//  Created by 强邹 on 2017/11/29.
//  Copyright © 2017年 Lance Wu. All rights reserved.
//

#import "LoadingView.h"
#import "Masonry.h"
@implementation LoadingView

-(instancetype)initWithTitle:(NSString *)title{
    self = [super init];
    self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleGray)];
        //设置小菊花的frame
    self.activityIndicator.frame= CGRectMake(0, 5, 20, 20);
    self.activityIndicator.color =[UIColor lightGrayColor];
        //设置小菊花颜色
    self.view = [[UIView alloc]initWithFrame:CGRectMake((kScreenWidth-200)/2, (kScreenHeight-100)/2, 200, 100)];
    [self.view addSubview:self.activityIndicator];
    self.loading_tv = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 200, 30)];
    self.loading_tv.text=title;
    self.loading_tv.textAlignment = NSTextAlignmentCenter;
    self.loading_tv.textColor=[UIColor lightGrayColor];
    self.loading_tv.enabled = NO;
    self.loading_tv.userInteractionEnabled =NO;
    
    [self.loading_tv setFont:[UIFont fontWithName:@"Arial" size:14 ] ];
    
    [self.loading_tv setBackgroundColor:[UIColor clearColor] ];
    [self.view addSubview:self.loading_tv];
    [self.view addSubview:self.activityIndicator];
    
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.mas_equalTo(self.view);
        make.width.width.mas_offset(30);
    }];
    [self.loading_tv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.activityIndicator.mas_trailing).mas_offset(4);
        make.top.bottom.trailing.mas_equalTo(self.view);
    }];
    
        //设置背景颜色
    self.activityIndicator.backgroundColor = [UIColor clearColor];
    
    self.activityIndicator.hidesWhenStopped = NO;
    
    [self.activityIndicator startAnimating];
    
    
    return self;
}



-(instancetype)initWithWebViewTitle:(NSString *)title{
    self = [super init];
    self.activityIndicator = [[UIActivityIndicatorView alloc]initWithActivityIndicatorStyle:(UIActivityIndicatorViewStyleGray)];
        //设置小菊花的frame
    self.activityIndicator.frame= CGRectMake(0, 5, 20, 20);
    self.activityIndicator.color =[UIColor lightGrayColor];
        //设置小菊花颜色
    self.view = [[UIView alloc]initWithFrame:CGRectMake(kScreenWidth/2-50, kScreenHeight/2-100, 200, 100)];
    [self.view addSubview:self.activityIndicator];
    self.loading_tv = [[UILabel alloc]initWithFrame:CGRectMake(20, 0, 200, 30)];
    self.loading_tv.text=title;
    self.loading_tv.textColor=[UIColor lightGrayColor];
    [self.loading_tv setFont:[UIFont fontWithName:@"Arial" size:14 ] ];
    self.loading_tv.enabled = NO;
    self.loading_tv.userInteractionEnabled =NO;
    [self.loading_tv setBackgroundColor:[UIColor clearColor] ];
    [self.view addSubview:self.loading_tv];
    [self.view addSubview:self.activityIndicator];
    
    [self.activityIndicator mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.top.bottom.mas_equalTo(self.view);
        make.width.width.mas_offset(30);
    }];
    [self.loading_tv mas_makeConstraints:^(MASConstraintMaker *make) {
        make.leading.mas_equalTo(self.activityIndicator.mas_trailing).mas_offset(4);
        make.top.bottom.trailing.mas_equalTo(self.view);
    }];
        //设置背景颜色
    self.activityIndicator.backgroundColor = [UIColor clearColor];
    
    self.activityIndicator.hidesWhenStopped = NO;
    
    [self.activityIndicator startAnimating];
    
    
    return self;
}

@end
