//
//  NativeXRewardInfo.h
//  NativeXSDK
//
//  Created by Joel Braun on 2015.02.09.
//
//

#import <Foundation/Foundation.h>
#include "NativeXReward.h"

@interface NativeXRewardInfo : NSObject

/*
 * Array of NativeXRewards detailing exact rewards to be given to the user
 */
@property (nonatomic, readonly) NSArray* rewards;

/**
 *  Create CurrencyInfo object using API JSON response
 *
 *  @param APIResult    NSDictionary of API results
 *
 *  @return an object version of json response
 */
-(id)initWithRedeemBalancesResult:(NSDictionary *)APIResult;

/**
 *  Calling this method will display a native iOS alert view on success
 */
-(void)showRedeemAlert;

/**
 *  converts object to dictionary (to prep for JSON)
 *
 *  @return NSDictionary version of object
 */
-(id)proxyForJson;

@end

#pragma mark NativeXRewardDelegate protocol definition

@protocol NativeXRewardDelegate <NSObject>

@required

/** Called when the currency redemption is unsuccessfull.
 *
 * @param   error
 *          reason why redeem currency call failed
 */
- (void)rewardDidRedeemWithError:(NSError *)error;


/** Called when the rewards redemption is successful.
 *
 * @param rewardInfo
 *        an object containing the list of reciepts, as well as some helper methods
 */
- (void)rewardDidRedeemWithRewardInfo:(NativeXRewardInfo*)rewardInfo;

@end
