//
//  FlurryBannerCustomEvent.m
//  MoPub Mediates Flurry
//
//  Created by Bisera Ferrero on 9/30/13.
//  Copyright (c) 2013 Flurry. All rights reserved.
//

#import "FlurryBannerCustomEvent.h"

#import "FlurryAdDelegate.h"
#import "FlurryAds.h"
#import "FlurryAdsCustomRouter.h"

#import "MPLogging.h"
#import "MPInstanceProvider.h"

/*
 * Provde adSpaceName param when configuring Flurry as the Custom Native Network
 * in the MoPub web interface {"adSpaceName": "YOUR_FLURRY_AD_SPACE_NAME"}.
 * If adSpaceName is not found, this adapter will use "BANNER_AD" as the Flurry ad space name.
 */
#define FlurryAdSpaceName @"BANNER_AD"
#define FlurryAdPlacement BANNER_BOTTOM

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPFlurryBannerDelegate : MPFlurryAdDelegate <FlurryAdDelegate>

@property (nonatomic, assign) CGRect adViewFrame;

+ (MPFlurryBannerDelegate *)sharedInstance;

- (BOOL)isBannerAvailableForSpace:(NSString *) adSpace;

- (void)fetchBannerForSpace:(NSString *)adSpace
             forAdViewFrame:(CGRect)adViewFrame
            forFlurryBannerCustomEvent:(FlurryBannerCustomEvent *)event;

- (void)displayBannerForSpace:(NSString *)adSpace
   forFlurryBannerCustomEvent:(FlurryBannerCustomEvent *)event;

- (FlurryBannerCustomEvent *)eventForSpace:(NSString *)space isOnScreen:(BOOL)onScreen;
- (void)setEvent:(FlurryBannerCustomEvent *)event forSpace:(NSString *)space;
- (void)invalidateEvent:(FlurryBannerCustomEvent *)event forSpace:(NSString *)space;
- (BOOL)isEvent: (FlurryBannerCustomEvent *)event forSpace:(NSString *)space ;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPInstanceProvider (FlurryBanners)
- (MPFlurryBannerDelegate *)sharedMPFlurryBannerDelegate;
@end

@implementation MPInstanceProvider (FlurryBanners)

- (MPFlurryBannerDelegate *)sharedMPFlurryBannerDelegate
{
    return [self singletonForClass:[MPFlurryBannerDelegate class]
                          provider:^id{
                              return [[MPFlurryBannerDelegate alloc] init];
                          }];
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////


@interface  FlurryBannerCustomEvent()
@property (nonatomic, assign) BOOL onScreen;
@property (nonatomic, strong) NSString *adSpaceName;

@end


@implementation FlurryBannerCustomEvent

@synthesize onScreen = _onScreen;

- (void)requestAdWithSize:(CGSize)size customEventInfo:(NSDictionary *)info
{
    MPLogInfo(@"MoPub instructs Flurry to display an ad in [%@], of size: %f, %f" , [info objectForKey:@"adSpaceName"], size.width, size.height);
    
    self.adSpaceName = [info objectForKey:@"adSpaceName"];
    if (!self.adSpaceName) {
        self.adSpaceName = FlurryAdSpaceName;
    }
    
    self.onScreen = NO;
    CGRect theRect = CGRectMake(0, 0, size.width, size.height);
    
    [[MPInstanceProvider sharedProvider] delegateFlurry:[FlurryAdsCustomRouter sharedRouter]];
    
    if ([[MPFlurryBannerDelegate sharedInstance] isBannerAvailableForSpace:self.adSpaceName] ) {
        
        [[MPFlurryBannerDelegate sharedInstance] displayBannerForSpace:self.adSpaceName  forFlurryBannerCustomEvent:self];
        
    } else {
       
        [[MPFlurryBannerDelegate sharedInstance] fetchBannerForSpace:self.adSpaceName
                                                  forAdViewFrame:theRect
                                      forFlurryBannerCustomEvent:self];
    }
    
}

- (void)invalidate {
    MPLogInfo(@"MoPub invalidate Flurry Custom Event, %@" , self);
    self.onScreen = NO;
    [[MPFlurryBannerDelegate sharedInstance] invalidateEvent:self forSpace:self.adSpaceName];
    
}

- (void)didDisplayAd {
    MPLogInfo(@"MoPub Custom Event %@ didDisplayAd by Flurry " , self);
    self.onScreen = YES;
}

- (BOOL)enableAutomaticImpressionAndClickTracking
{
    return NO;
}

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

/*
 * Flurry only provides a shared instance, so only one object may be the FlurryAds delegate at
 * any given time. However, because it is common to request Flurry banners for separate
 * adSpaces in a single app session, we may have multiple instances of our custom event class,
 * all of which are interested in delegate callbacks.
 *
 * MPFlurryBannerRouter is a singleton that is always the FlurryAd delegate, and dispatches
 * events to all of the custom event instances.
 */

@implementation MPFlurryBannerDelegate

@synthesize adViewFrame = _adViewFrame;

+ (MPFlurryBannerDelegate *)sharedInstance
{
    return [[MPInstanceProvider sharedProvider] sharedMPFlurryBannerDelegate];
}

- (id)init
{
    self = [super init];
    if (self) {
    }
    
    return self;
}

- (void)dealloc
{
    MPLogInfo(@"dealloc Flurry Banner Delegate");
}

- (void)fetchBannerForSpace:(NSString *)adSpace
             forAdViewFrame:(CGRect)adViewFrame
            forFlurryBannerCustomEvent:(FlurryBannerCustomEvent *)event {
    
    MPLogInfo(@"Flurry Ads being fetched for [%@]" , adSpace);
    [self setEvent:event forSpace:adSpace];
    [[FlurryAdsCustomRouter sharedRouter] setRouter:self forSpace:adSpace];
    self.adViewFrame = adViewFrame;
    
    [FlurryAds fetchAdForSpace:adSpace frame:adViewFrame size:FlurryAdPlacement];
    
    // Create the view to display the  ad
    // Flurry maintains one view for one adSpace, keep this view for the duration
    if ([self viewForSpace:adSpace] == nil) {
         MPLogInfo(@"Constructing Flurry view [%@]" , adSpace);
        [self setView:[[UIView alloc] initWithFrame:self.adViewFrame] forSpace:adSpace];
    }
}

- (BOOL)isBannerAvailableForSpace:(NSString *) adSpace;
{
    return [FlurryAds adReadyForSpace:adSpace];
}

- (void)displayBannerForSpace:(NSString *)adSpace
  forFlurryBannerCustomEvent:(FlurryBannerCustomEvent *)event
{
    MPLogInfo(@"Flurry Ads being displayed for [%@]" , adSpace);
    
    if(event!= nil) {
        //if displayAd is called from requestAdWithSize event is valid
        [self setEvent:event forSpace:adSpace];
    }

    if ([self viewForSpace:adSpace] == nil) {
        [self setView:[[UIView alloc] initWithFrame:self.adViewFrame] forSpace:adSpace];
    }
    
    if ([self isEvent:event forSpace:adSpace]) {
        [FlurryAds displayAdForSpace:adSpace onView:[self viewForSpace:adSpace] viewControllerForPresentation:[event.delegate viewControllerForPresentingModalView]];
    } else {
        MPLogInfo(@"No valid event found skipping the display");
    }
}

- (FlurryBannerCustomEvent *)eventForSpace:(NSString *)space isOnScreen:(BOOL)onScreen{
    /*
     * There can be 2 events that use the same adspace, however,
     * Flurry maintains the invariant that only one active adspace is allowed
     * at a time so that adSpace can't show on two different views (would result in side effects)
     */
    
    NSMutableSet *eventSet = [self.adSpaceToEventsMap objectForKey: space];
    
    if (eventSet) {
        for (FlurryBannerCustomEvent *eventOnScreen in eventSet)
        {
            if (eventOnScreen.onScreen == onScreen) {
                return eventOnScreen;
            }
        }
    }
    return nil;
}

- (void)setEvent:(FlurryBannerCustomEvent *)event forSpace:(NSString *)space {
    NSMutableSet *eventSet = [self.adSpaceToEventsMap objectForKey: space];
    
    if (!eventSet) {
        eventSet = [[NSMutableSet alloc] init];
        
        [self.adSpaceToEventsMap setObject: eventSet forKey:space];
    }
    
    [eventSet addObject:event];
}

- (void)invalidateEvent:(FlurryBannerCustomEvent *)event forSpace:(NSString *)space{
   
    NSMutableSet *eventSet = [self.adSpaceToEventsMap objectForKey: space];
    
    if (eventSet) {
        if ([eventSet containsObject: event]) {
            [eventSet removeObject:event];
        } else {
            MPLogInfo(@"Flurry Custom Event is missing, something went terribly wrong.");
        }
    }
    
    /*
     * The real cleanup is perfromed when only when leaving the UIVIewController
     * that holds the ad placement.
     * If the eventToOnScreenMap count > 0 the refresh is still ongoing,
     * removing the view would result in side effects, thus only done when leving
     */
    if ([eventSet count] == 0) {
        [FlurryAds removeAdFromSpace:space];
        [self.adSpaceToViewMap removeObjectForKey:space];
        [self.adSpaceToEventsMap removeObjectForKey:space];
        [self.adSpaceClickMap removeObjectForKey:space];
    }
}

- (BOOL)isEvent: (FlurryBannerCustomEvent *)event forSpace:(NSString *)space {
    
    
    NSMutableSet *eventSet =[self.adSpaceToEventsMap objectForKey: space];
    if (eventSet) {
        if ([eventSet containsObject: event]) {
            return YES;
        }
    }
    return NO;
    
}

#pragma mark - FlurryAdDelegate
- (void)spaceDidReceiveAd:(NSString *)adSpace
{
    MPLogInfo(@"Flurry Ad Space [%@] spaceDidReceiveAd  ", adSpace);
    [self displayBannerForSpace:adSpace forFlurryBannerCustomEvent:[self eventForSpace:adSpace isOnScreen:NO]];
}

- (void)spaceDidFailToReceiveAd:(NSString*)adSpace error:(NSError *)error
{
    MPLogInfo(@"Flurry Ad Space [%@] spaceDidFailToReceiveAd   %@", adSpace, error.userInfo[@"NSLocalizedDescription"]);
    // Tell MoPub the ad failed to show up
    [[self eventForSpace:adSpace isOnScreen:NO].delegate bannerCustomEvent:[self eventForSpace:adSpace isOnScreen:NO] didFailToLoadAdWithError:error];
}

- (BOOL) spaceShouldDisplay:(NSString*)adSpace interstitial:(BOOL)interstitial {
    MPLogInfo(@"Flurry Ad Space [%@] Should Display Ad for interstitial [%d]  ", adSpace, interstitial);
    
    return YES;
}

- (void) spaceDidRender:(NSString *)space interstitial:(BOOL)interstitial {
    MPLogInfo(@"Flurry Ad Space [%@] did render Ad for interstitial [%d]  ", space, interstitial);
    // Tell MoPub Flurry ad is about to be rendered
    // If Flurry ad rotation frequency is greater than that of mopub we need to count more impressions.
    FlurryBannerCustomEvent * customEvent;
    customEvent = [self eventForSpace:space isOnScreen:YES];
    if (customEvent != nil)
    {
        customEvent.onScreen = NO;
    }
    
    customEvent = [self eventForSpace:space isOnScreen:NO];
    if (customEvent != nil)
    {
        [customEvent.delegate trackImpression];
        [customEvent.delegate bannerCustomEvent:customEvent didLoadAd:[self viewForSpace:space]];
        //  Set the ad space click map to unclicked as we have new ad to show
        [self.adSpaceClickMap setObject:[NSNumber numberWithBool:NO] forKey:space];
    }
}

- (void) spaceDidFailToRender:(NSString *) adSpace error:(NSError *)error {
    MPLogInfo(@"Flurry Ad Space [%@] Did Fail to Render with error [%@]  ", adSpace, error);
    [[self eventForSpace:adSpace isOnScreen:NO].delegate bannerCustomEvent:[self eventForSpace:adSpace isOnScreen:NO] didFailToLoadAdWithError:error];
}

- (void)spaceDidReceiveClick:(NSString*)adSpace
{
    MPLogInfo(@"Flurry Ad Space [%@] Did Receive Click  ", adSpace);
    
    if (![[self.adSpaceClickMap objectForKey:adSpace] boolValue]) {
        [[self eventForSpace:adSpace isOnScreen:YES].delegate trackClick];
        [self.adSpaceClickMap setObject:[NSNumber numberWithBool:YES] forKey:adSpace];
    }
}

- (void) videoDidFinish:(NSString *)adSpace{
    MPLogInfo(@"Flurry Ad Space [%@] Video Did Finish   ", adSpace);
}

- (void)spaceWillDismiss:(NSString *)adSpace interstitial:(BOOL)interstitial {
    MPLogInfo(@"Flurry Ad Space [%@] Will Dismiss for interstitial [%d]  ", adSpace, interstitial);
}

- (void)spaceDidDismiss:(NSString *)adSpace interstitial:(BOOL)interstitial {
    MPLogInfo(@"Flurry Ad Space [%@] Did Dismiss for interstitial [%d]  ", adSpace, interstitial);
}

- (void)spaceWillLeaveApplication:(NSString *)adSpace {
    MPLogInfo(@"Flurry Ad Space [%@] Will Leave Application  ", adSpace);
    FlurryBannerCustomEvent *customEvent = [self eventForSpace:adSpace isOnScreen:YES];
    
    if (![[self.adSpaceClickMap objectForKey:adSpace] boolValue]) {
        [customEvent.delegate trackClick];
        [self.adSpaceClickMap setObject:[NSNumber numberWithBool:YES] forKey:adSpace];
    }
    
    [customEvent.delegate bannerCustomEventWillLeaveApplication:customEvent];
    
}

- (void)spaceWillExpand:(NSString *)adSpace {
    MPLogInfo(@"Flurry Ad Space [%@] Will Expand  ", adSpace);
    [[self eventForSpace:adSpace isOnScreen:YES].delegate bannerCustomEventWillBeginAction:[self eventForSpace:adSpace isOnScreen:YES]];
}

- (void)spaceDidCollapse:(NSString *)adSpace {
    MPLogInfo(@"Flurry Ad Space [%@] Did Collapse  ", adSpace);
    [[self eventForSpace:adSpace isOnScreen:YES].delegate bannerCustomEventDidFinishAction:[self eventForSpace:adSpace isOnScreen:YES]];
}

@end

