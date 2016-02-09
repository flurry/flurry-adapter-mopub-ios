//
//  FlurryMPConfig.m
//  MoPub Mediates Flurry
//
//  Created by Flurry.
//  Copyright (c) 2015 Yahoo, Inc. All rights reserved.
//

#import "FlurryMPConfig.h"

@implementation FlurryMPConfig

+ (void)initializeWithFlurryAPIKey:(NSString *)flurryAPIKey
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        [Flurry startSession:flurryAPIKey];
        [Flurry addOrigin:FlurryMediationOrigin withVersion:FlurryAdapterVersion];
        [Flurry setDebugLogEnabled:NO];
    });
}

@end
