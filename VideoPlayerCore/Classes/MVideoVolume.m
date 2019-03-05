//
//  MVideoVolume.m
//  Thunder
//
//  Created by 鞠汶成 on 2018/12/23.
//  Copyright © 2018 Lance Wu. All rights reserved.
//

#import "MVideoVolume.h"

@implementation MVideoVolume

+ (instancetype)modelFromJson:(NSDictionary *)json {
    MVideoVolume *volume = [[self alloc] init];
    volume.title = [self safeString:json[@"title"]];
    volume.url = [self safeString:json[@"url"]];
    volume.order = [[self safeString:json[@"order"]] integerValue];
    volume.type = [[self safeString:json[@"type"]] integerValue];
    return volume;
}

+ (NSString *)safeString:(NSString *)string {
    if ([string isKindOfClass:[NSNull class]]) return @"";
    if ([string isKindOfClass:[NSString class]]) {
        return string;
    }else {
        if (string == nil) {
            return @"";
        }
        return [NSString stringWithFormat:@"%@", string];
    }
}

@end
