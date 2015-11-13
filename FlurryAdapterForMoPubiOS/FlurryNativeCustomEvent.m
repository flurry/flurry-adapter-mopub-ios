//
//  FlurryNativeCustomEvent.m
//  MoPub Mediates Flurry
//
//  Created by Flurry.
//  Copyright (c) 2015 Yahoo, Inc. All rights reserved.
//

#import "FlurryNativeCustomEvent.h"
#import "FlurryAdNative.h"
#import "FlurryNativeAdAdapter.h"
#import "MPNativeAd.h"
#import "MPNativeAdError.h"
#import "MPLogging.h"

@interface FlurryNativeCustomEvent () <FlurryAdNativeDelegate>

@property (nonatomic, retain) FlurryAdNative *adNative;

@end

@implementation FlurryNativeCustomEvent

- (void)requestAdWithCustomEventInfo:(NSDictionary *)info
{
    NSString *adSpace = [info objectForKey:@"adSpaceName"];
    if (adSpace) {
        self.adNative = [[FlurryAdNative alloc] initWithSpace:adSpace];
        self.adNative.adDelegate = self;
        [self.adNative fetchAd];
    } else {
        [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:[NSError errorWithDomain:MoPubNativeAdsSDKDomain code:MPNativeAdErrorInvalidServerResponse userInfo:nil]];
    }
}

#pragma mark - Flurry Ad Delegates

- (void) adNativeDidFetchAd:(FlurryAdNative *)flurryAd
{
    MPLogDebug(@"Flurry native ad fetched (customEvent)");
    FlurryNativeAdAdapter *adAdapter = [[FlurryNativeAdAdapter alloc] initWithFlurryAdNative:flurryAd];
    MPNativeAd *interfaceAd = [[MPNativeAd alloc] initWithAdAdapter:adAdapter];
    
    [self.delegate nativeCustomEvent:self didLoadAd:interfaceAd];
}

- (void) adNative:(FlurryAdNative *)flurryAd adError:(FlurryAdError)adError errorDescription:(NSError *)errorDescription
{
    MPLogDebug(@"Flurry native ad failed to load with error (customEvent): %@", errorDescription.description);
    [self.delegate nativeCustomEvent:self didFailToLoadAdWithError:errorDescription];
}

@end
