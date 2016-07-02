//
//  NativeXController.h
//  SolarConquest
//
//  Created by Carlos Beltran on 8/8/15.
//  Copyright (c) 2015 Carlos. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import "NativeXSDK.h"

@interface NativeXController: UIResponder <NativeXSDKDelegate, NativeXAdViewDelegate>

-(void) createSessionWithAppID:(NSString*)appID;
-(void) fetchPlacement;
-(void) displayPlacement;

@end
