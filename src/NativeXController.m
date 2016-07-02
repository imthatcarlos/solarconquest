//
//  NativeXController.m
//  SolarConquest
//
//  Created by Carlos Beltran on 8/8/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

#import "NativeXController.h"
#import "NativeXSDK.h"
#import "SolarConquest-Swift.h"

@implementation NativeXController

- (id) init
{
    return [super init];
}

- (void) createSessionWithAppID:(NSString*)appID
{
    
    [[NativeXSDK sharedInstance] setDelegate:self ];
    
    [[NativeXSDK sharedInstance] createSessionWithAppId:appID];
    
}

- (void) fetchPlacement
{
    [[NativeXSDK sharedInstance] fetchAdWithCustomPlacement:@"CurrencyShower" delegate:self];
}

- (void) displayPlacement
{
    [[NativeXSDK sharedInstance] showReadyAdWithCustomPlacement:@"CurrencyShower"];
}

// Called if the SDK initializes successfully
- (void)nativeXSDKDidCreateSession {
    //NSLog(@"NativeX launch successful.");
    
    [self fetchPlacement];
}

// Called if the SDK fails to initialize.
- (void)nativeXSDKDidFailToCreateSession:(NSError *)error {
    //NSLog(@"NativeX launch failed!");
    
    GameScene *gs = [GameScene sharedInstance];
    [gs onNativeXError];
}

- (void) nativeXSDKDidRedeemWithRewardInfo:(NativeXRewardInfo *)rewardInfo {
    
    // Add code to handle the reward info and credit your user here.
    int totalRewardAmount = 0;
    for (NativeXReward *reward in rewardInfo.rewards) {
        // grab the amount and add it to total
        totalRewardAmount += [reward.amount intValue];
    }
    
    if (totalRewardAmount != 0) {
        GameScene *gs = [GameScene sharedInstance];
        [gs addNativeXReward:totalRewardAmount];
        
    }
}

//Called right before ad is about to display
- (void)nativeXAdViewWillDisplay:(NativeXAdView *)adView
{
    if (adView.willPlayAudio) {
        
        AudioManager *am = [AudioManager sharedInstance];
        [am pauseMusic];
    }
}
//Called after ad is fully dismissed
- (void)nativeXAdViewDidDismiss:(NativeXAdView *)adView
{
    if (adView.willPlayAudio) {
        
        AudioManager *am = [AudioManager sharedInstance];
        [am resumeMusic];
    }
    
    [self fetchPlacement];
}

- (void)nativeXAdView:(NativeXAdView *)adView didLoadWithPlacement:(NSString *)placement
{
    //Called when an ad has been loaded/cached and is ready to be shown
    //NSLog(@"Placement %@ is ready to be displayed!", placement);
}

- (void)nativeXSDKDidRedeemWithError:(NSError *)error {
    // Called when the currency redemption is unsuccessful
}

@end