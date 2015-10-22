//
//  FlurryNativeAdAdapter.m
//  MoPub Mediates Flurry
//
//  Created by Flurry.
//  Copyright (c) 2015 Yahoo, Inc. All rights reserved.
//

#import "FlurryNativeAdAdapter.h"
#import "FlurryAdNativeDelegate.h"
#import "MPNativeAdConstants.h"
#import "MPNativeAdError.h"
#import "MPLogging.h"

@interface FlurryNativeAdAdapter() <FlurryAdNativeDelegate>

@property (nonatomic, strong) FlurryAdNative *adNative;

@end

@implementation FlurryNativeAdAdapter

@synthesize properties = _properties;

- (instancetype)initWithFlurryAdNative:(FlurryAdNative *)adNative
{
    self = [super init];
    if (self) {
        _adNative = adNative;
        _adNative.adDelegate = self;
        
        NSMutableDictionary *props = [NSMutableDictionary dictionary];
        for (int ix = 0; ix < adNative.assetList.count; ++ix) {
            FlurryAdNativeAsset* asset = [adNative.assetList objectAtIndex:ix];
            if ([asset.name isEqualToString:@"headline"]) {
                [props setObject:asset.value forKey:kAdTitleKey];
            }
            
            if ([asset.name isEqualToString:@"secImage"]) {
                [props setObject:asset.value forKey:kAdIconImageKey];
            }
            
            if ([asset.name isEqualToString:@"secHqImage"]) {
                [props setObject:asset.value forKey:kAdMainImageKey];
            }
            
            if ([asset.name isEqualToString:@"summary"]) {
                [props setObject:asset.value forKey:kAdTextKey];
            }
           
            if ([asset.name isEqualToString:@"appRating"]) {
                [props setObject:asset.value forKey:kAdStarRatingKey];
            }

            if ([asset.name isEqualToString:@"callToAction"]) {
                [props setObject:asset.value forKey:kAdCTATextKey];
            }
            
        }
        _properties = props;
    }
    return self;
}

- (void)dealloc {
    _adNative.adDelegate = nil;
    _adNative = nil;
}

#pragma mark - MPNativeAdAdapter

- (NSTimeInterval)requiredSecondsForImpression
{
    return 0.0;
}

- (NSURL *)defaultActionURL
{
    return nil;
}

- (BOOL)enableThirdPartyClickTracking
{
    return YES;
}

- (void)willAttachToView:(UIView *)view
{
    self.adNative.trackingView = view;
    self.adNative.viewControllerForPresentation = [self.delegate viewControllerForPresentingModalView];
}

- (void)didDetachFromView:(UIView *)view
{
    [self.adNative removeTrackingView];
}

#pragma mark - Flurry Ad Delegates

- (void) adNativeWillPresent:(FlurryAdNative*) nativeAd {
    MPLogDebug(@"Flurry native ad will present (adapter)");
    if ([self.delegate respondsToSelector:@selector(nativeAdWillPresentModalForAdapter:)]) {
        [self.delegate nativeAdWillPresentModalForAdapter:self];
    }
}

- (void) adNativeWillLeaveApplication:(FlurryAdNative*) nativeAd {
    MPLogDebug(@"Flurry native ad will leave application (adapter)");
    if ([self.delegate respondsToSelector:@selector(nativeAdWillLeaveApplicationFromAdapter:)]) {
        [self.delegate nativeAdWillLeaveApplicationFromAdapter:self];
    }
}

- (void) adNativeWillDismiss:(FlurryAdNative*) nativeAd {
    MPLogDebug(@"Flurry native ad will dismiss (adapter)");
}

- (void) adNativeDidDismiss:(FlurryAdNative*) nativeAd {
    MPLogDebug(@"Flurry native ad did dismiss (adapter)");
    if ([self.delegate respondsToSelector:@selector(nativeAdDidDismissModalForAdapter:)]) {
        [self.delegate nativeAdDidDismissModalForAdapter:self];
    }
}

- (void) adNativeDidReceiveClick:(FlurryAdNative*) nativeAd {
    MPLogDebug(@"Flurry native ad was clicked (adapter)");
    if ([self.delegate respondsToSelector:@selector(nativeAdDidClick:)]) {
        [self.delegate nativeAdDidClick:self];
    } else {
        MPLogWarn(@"Delegate does not implement click tracking callback. Clicks likely not being tracked.");
    }
}

- (void) adNativeDidLogImpression:(FlurryAdNative*) nativeAd {
    MPLogDebug(@"Flurry native ad was shown (adapter)");
    if ([self.delegate respondsToSelector:@selector(nativeAdWillLogImpression:)]) {
        [self.delegate nativeAdWillLogImpression:self];
    } else {
        MPLogWarn(@"Delegate does not implement impression tracking callback. Impression likely not being tracked.");
    }
}

@end
