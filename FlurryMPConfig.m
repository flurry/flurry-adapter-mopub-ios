//
//  FlurryMPConfig.m
//  MoPub Mediates Flurry
//
//  Created by Flurry.
//  Copyright (c) 2015 Yahoo, Inc. All rights reserved.
//

#import "FlurryMPConfig.h"

@implementation FlurryMPConfig

+ (void)startSessionWithApiKey:(NSString *)apiKey {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [Flurry startSession:apiKey];
        [Flurry addOrigin:FlurryMediationOrigin withVersion:FlurryAdapterVersion];
        [Flurry setDebugLogEnabled:NO];
    });
}

@end
