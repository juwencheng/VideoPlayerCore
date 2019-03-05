//
//  MVideoVolume.h
//  Thunder
//
//  Created by 鞠汶成 on 2018/12/23.
//  Copyright © 2018 Lance Wu. All rights reserved.
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface MVideoVolume : NSObject

+ (instancetype)modelFromJson:(NSDictionary *)json;

@property (nonatomic, copy) NSString *url;
@property (nonatomic, copy) NSString *title;
@property (nonatomic, assign) NSInteger order;
@property (nonatomic, assign) NSInteger type;// 0 普通 1 预告 2 vip
@end

NS_ASSUME_NONNULL_END
