//
//  AHAAllihoopaSDK.h
//  Allihoopa
//
//  Created by Magnus Hallin on 23/09/16.
//  Copyright © 2016 Allihoopa. All rights reserved.
//

#import <Foundation/Foundation.h>

typedef void (^AHAAuthenticationCallback)(BOOL successful);

@interface AHAAllihoopaSDK : NSObject

+ (void)setup;

+ (void)authenticate:(AHAAuthenticationCallback _Nonnull)completion;

+ (BOOL)handleOpenURL:(NSURL* _Nonnull)url;

@end
