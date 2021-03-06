//
//  Allihoopa+Internal.m
//  Allihoopa
//
//  Created by David Ventura on 1/17/17.
//  Copyright © 2017 Allihoopa. All rights reserved.
//

#import "Allihoopa+Internal.h"
#import "AllihoopaSDK.h"

NSBundle* AHAGetResourceBundle(void)
{
	NSURL* cocoaPodsBundleURL = [[NSBundle bundleForClass:[AHAAllihoopaSDK class]] URLForResource:@"Allihoopa" withExtension:@"bundle"];
	NSBundle* assetBundle;
	
	if (cocoaPodsBundleURL) {
		assetBundle = [NSBundle bundleWithURL:cocoaPodsBundleURL];
	}
	
	if (!assetBundle) {
		assetBundle = [NSBundle bundleForClass:[AHAAllihoopaSDK class]];
	}

	NSCAssert( assetBundle, @"Could not find Allihoopa resource bundle. Is it included properly?" );
	
	return assetBundle;
}

NSBundle* AHAGetCoreResourceBundle(void)
{
	NSURL* cocoaPodsBundleURL = [[NSBundle bundleForClass:[AHABaseAllihoopaSDK class]] URLForResource:@"AllihoopaCore" withExtension:@"bundle"];
	NSBundle* assetBundle;

	if (cocoaPodsBundleURL) {
		assetBundle = [NSBundle bundleWithURL:cocoaPodsBundleURL];
	}

	if (!assetBundle) {
		assetBundle = [NSBundle bundleForClass:[AHABaseAllihoopaSDK class]];
	}

	NSCAssert( assetBundle, @"Could not find AllihoopaCore resource bundle. Is it included properly?" );

	return assetBundle;
}
