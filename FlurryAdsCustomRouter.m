//
//  FlurryAdsCustomRouter.m
//  MoPub Mediates Flurry
//
//  Copyright (c) 2013 Flurry. All rights reserved.
//

#import "FlurryAdsCustomRouter.h"
#import "MPLogging.h"
#import "MPInstanceProvider.h"

#import "Flurry.h"
#import "FlurryAds.h"

#define FlurryAPIKey @"YOUR_FLURRY_API_KEY"
#define FlurryMediationOrigin @"Flurry_Mopub_iOS"
#define FlurryAdapterVersion @"6.0.0.r1"

/*
 * Flurry only provides a shared instance, so only one object may be the FlurryAds delegate at
 * any given time for both banners and takeovers. We therefore need a Router that will communicate
 * delegate callbacks to the correct Banner or Takeover router. This is that class.
 *
 * FlurryAdsCustomRouter is a singleton that is always the global FlurryAd delegate.
 */

@interface FlurryAdsCustomRouter () 

// Map of the ad spaces to the proper router
@property (nonatomic,strong) NSMutableDictionary *adSpaceToRouterMap;

- (id<FlurryAdDelegate>)routerForSpace:(NSString *)space;

@end

@implementation MPInstanceProvider (FlurryAdsRouterBridge)

- (void) delegateFlurry: id
{
    [FlurryAds setAdDelegate:id];
}


- (FlurryAdsCustomRouter *)sharedFlurryAdsCustomRouter
{
    return [self singletonForClass:[FlurryAdsCustomRouter class]
                          provider:^id{
                              return [[FlurryAdsCustomRouter alloc] init];
                          }];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@implementation FlurryAdsCustomRouter

@synthesize adSpaceToRouterMap = _adSpaceToRouterMap;

+ (FlurryAdsCustomRouter *)sharedRouter
{
    return [[MPInstanceProvider sharedProvider] sharedFlurryAdsCustomRouter];
}

- (id)init
{
    MPLogInfo(@"Intialize Flurry Ads Router");
    self = [super init];
    if (self) {
        self.adSpaceToRouterMap = [NSMutableDictionary dictionary];
        
        [Flurry startSession:FlurryAPIKey];
        [Flurry addOrigin:FlurryMediationOrigin withVersion:FlurryAdapterVersion];
        [Flurry setDebugLogEnabled:NO];
        
        MPLogInfo(@"Intialize Flurry Custom Router, version %@: ",FlurryAdapterVersion );
    }
    
    return self;
}

- (void)dealloc
{
    MPLogInfo(@"dealloc Flurry Ads Router");
    [[MPInstanceProvider sharedProvider] delegateFlurry:nil];
    self.adSpaceToRouterMap = nil;
}

- (id<FlurryAdDelegate>)routerForSpace:(NSString *)space
{
    return [self.adSpaceToRouterMap objectForKey:space];
}

- (void)setRouter:(id<FlurryAdDelegate>)router forSpace:(NSString *)space
{
    [self.adSpaceToRouterMap setObject:router forKey:space];
}

#pragma mark - FlurryAdDelegate
- (void)spaceDidReceiveAd:(NSString *)adSpace
{
    MPLogInfo(@"Routing Ad Space [%@] spaceDidReceiveAd", adSpace);
    [[self routerForSpace:adSpace] spaceDidReceiveAd:adSpace];
}

- (void)spaceDidFailToReceiveAd:(NSString*)adSpace error:(NSError *)error
{
    MPLogInfo(@"Routing Ad Space [%@] spaceDidFailToReceiveAd %@", adSpace, error.userInfo[@"NSLocalizedDescription"]);

    [[self routerForSpace:adSpace] spaceDidFailToReceiveAd:adSpace error:error];
}

- (BOOL) spaceShouldDisplay:(NSString*)adSpace interstitial:(BOOL)interstitial {
    MPLogInfo(@"Routing Ad Space [%@] Should Display Ad for interstitial [%d]", adSpace, interstitial);

    return [[self routerForSpace:adSpace] spaceShouldDisplay:adSpace interstitial:interstitial];
}

- (void) spaceDidFailToRender:(NSString *) adSpace error:(NSError *)error {
    MPLogInfo(@"Routing Ad Space [%@] Did Fail to Render with error [%@]", adSpace, error);
    
    [[self routerForSpace:adSpace] spaceDidFailToRender:adSpace error:error];
}

- (void) spaceDidRender:(NSString *)space interstitial:(BOOL)interstitial
{
    MPLogInfo(@"Routing Ad Space [%@] Did Render", space);
    
    [[self routerForSpace:space] spaceDidRender:space interstitial:YES];
}

- (void)spaceWillDismiss:(NSString *)adSpace interstitial:(BOOL)interstitial {
    MPLogInfo(@"Routing Ad Space [%@] Will Dismiss for interstitial [%d]", adSpace, interstitial);
    
    [[self routerForSpace:adSpace] spaceWillDismiss:adSpace interstitial:interstitial];
}

- (void)spaceDidDismiss:(NSString *)adSpace interstitial:(BOOL)interstitial {
    MPLogInfo(@"Routing Ad Space [%@] Did Dismiss for interstitial [%d]", adSpace, interstitial);
    
    [[self routerForSpace:adSpace] spaceDidDismiss:adSpace interstitial:interstitial];
}

- (void)spaceWillLeaveApplication:(NSString *)adSpace {
    MPLogInfo(@"Routing Ad Space [%@] Will Leave Application", adSpace);

    [[self routerForSpace:adSpace] spaceWillLeaveApplication:adSpace];
}

- (void)spaceWillExpand:(NSString *)adSpace {
    MPLogInfo(@"Routing Ad Space [%@] Will Expand", adSpace);
    
    [[self routerForSpace:adSpace] spaceWillExpand:adSpace];
}

- (void)spaceDidCollapse:(NSString *)adSpace {
    MPLogInfo(@"Routing Ad Space [%@] Did Collapse", adSpace);
    
    [[self routerForSpace:adSpace] spaceDidCollapse:adSpace];
}

- (void)spaceWillCollapse:(NSString *)adSpace {
    MPLogInfo(@"Routing Ad Space [%@] Will Expand", adSpace);
    
    [[self routerForSpace:adSpace] spaceWillCollapse:adSpace];
}

- (void)spaceDidReceiveClick:(NSString*)adSpace
{
    MPLogInfo(@"Routing Ad Space  %@ Click received", adSpace);
    
    [[self routerForSpace:adSpace] spaceDidReceiveClick:adSpace];
}

- (void) videoDidFinish:(NSString *)adSpace{
    MPLogInfo(@"Routing Ad Space [%@] Video Did Finish", adSpace);
    
    [[self routerForSpace:adSpace] videoDidFinish:adSpace];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////

@implementation MPFlurryAdDelegate

@synthesize adSpaceClickMap = _adSpaceClickMap;
@synthesize adSpaceToEventsMap = _adSpaceToEventsMap;
@synthesize adSpaceToViewMap = _adSpaceToViewMap;

- (id)init
{
    self = [super init];
    if (self) {
        self.adSpaceClickMap = [NSMutableDictionary dictionary];
        self.adSpaceToEventsMap = [NSMutableDictionary dictionary];
        self.adSpaceToViewMap = [NSMutableDictionary dictionary];
    }
    
    return self;
}

- (void)dealloc
{
    MPLogInfo(@"dealloc Flurry Delegate");
    self.adSpaceClickMap = nil;
    self.adSpaceToEventsMap = nil;
    self.adSpaceToViewMap = nil;
}

// Flurry maintains one view for one adSpace, hold on to this view
- (void)setView:(UIView *)view forSpace:(NSString *)space {
    [self.adSpaceToViewMap setObject:view forKey:space];
}

- (UIView *)viewForSpace:(NSString *)adSpace {
    return [self.adSpaceToViewMap objectForKey:adSpace];
}

- (void)setClickStatus:(BOOL)status forSpace:(NSString*)space
{
    
    if ([self.adSpaceClickMap objectForKey:space] == nil) {
        [self.adSpaceClickMap setObject:[NSNumber numberWithBool:status] forKey:space];
    }
}

@end