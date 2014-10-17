//
//  FlurryAdsCustomRouter.h
//  MoPub Mediates Flurry
//
//  Copyright (c) 2013 MoPub. All rights reserved.
//

#import "FlurryAdDelegate.h"
#import "MPInstanceProvider.h"

@interface FlurryAdsCustomRouter : NSObject <FlurryAdDelegate>

+ (FlurryAdsCustomRouter *)sharedRouter;

- (void)setRouter:(id<FlurryAdDelegate>)router forSpace:(NSString *)space;

@end


////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPInstanceProvider (FlurryAdsRouterBridge)

- (FlurryAdsCustomRouter *)sharedFlurryAdsCustomRouter;
- (void) delegateFlurry: id;

@end

////////////////////////////////////////////////////////////////////////////////////////////////////

@interface MPFlurryAdDelegate : NSObject

// Map of the ad spaces that holds click status
@property (nonatomic,strong) NSMutableDictionary *adSpaceClickMap;
// Map of the ad spaces within the application
@property (nonatomic,strong) NSMutableDictionary *adSpaceToEventsMap;
// Map within adSpaceToEventsMap that holds multiple events
@property (nonatomic,strong) NSMutableDictionary *adSpaceToViewMap;

- (void)setClickStatus:(BOOL)status forSpace:(NSString*)space;
- (void)setView:(UIView *)view forSpace:(NSString *)space;
- (UIView *)viewForSpace:(NSString *)adSpace;

@end