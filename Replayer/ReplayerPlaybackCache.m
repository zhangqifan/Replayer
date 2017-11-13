//
//  ReplayerPlaybackCache.m
//
//  Created by zhangqifan on 2017/6/28.
//  Copyright © 2017年 zhangqifan. All rights reserved.
//

#import "ReplayerPlaybackCache.h"

static NSString * const ReplayerPlaybackCacheKey = @"REPLAYER_PLAYBACK_CACHE_IDENTIFIER";

@implementation ReplayerPlaybackCache

+ (void)setDownPlaybackCurrentMoment:(double)moment byVideoIdentifier:(NSString *)videoIdentifier {
    if (!videoIdentifier || videoIdentifier.length <= 0) { return; }
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    id cacheDict = [ud objectForKey:ReplayerPlaybackCacheKey];
    if (cacheDict && [cacheDict isKindOfClass:[NSDictionary class]]) {
        NSMutableDictionary *tempMutable = [cacheDict mutableCopy];
        [tempMutable setObject:[NSNumber numberWithDouble:moment] forKey:videoIdentifier];
        [ud setObject:[tempMutable copy] forKey:ReplayerPlaybackCacheKey];
    } else {
        [ud setObject:@{videoIdentifier:[NSNumber numberWithDouble:moment]} forKey:ReplayerPlaybackCacheKey];
    }
    [ud synchronize];
}

+ (double)fetchPlaybackMomentByVideoIdentifier:(NSString *)videoIdentifier {
    if (!videoIdentifier || videoIdentifier.length <= 0) { return 0; }
    NSUserDefaults *ud = [NSUserDefaults standardUserDefaults];
    id cacheDict = [ud objectForKey:ReplayerPlaybackCacheKey];
    if (cacheDict && [cacheDict isKindOfClass:[NSDictionary class]]) {
        return [[cacheDict objectForKey:videoIdentifier] doubleValue];
    }
    return 0;
}


@end
