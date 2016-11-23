//
//  AppDelegate.m
//  SDKExample-ObjC
//
//  Created by Magnus Hallin on 23/11/16.
//  Copyright © 2016 Allihoopa. All rights reserved.
//

#import "AppDelegate.h"

#import <Allihoopa/Allihoopa.h>

@interface AppDelegate () <AHAAllihoopaSDKDelegate>

@end

@implementation AppDelegate

- (void)applicationDidFinishLaunching:(UIApplication *)application {
	NSBundle* mainBundle = [NSBundle mainBundle];

	NSString* applicationIdentifier = [mainBundle objectForInfoDictionaryKey:@"AllihoopaSDKApplicationIdentifier"];
	NSString* apiKey = [mainBundle objectForInfoDictionaryKey:@"AllihoopaSDKAPIKey"];

	[AHAAllihoopaSDK setupWithApplicationIdentifier:applicationIdentifier
											 apiKey:apiKey
										   delegate:self];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	if ([AHAAllihoopaSDK handleOpenURL:url]) {
		return YES;
	}

	return NO;
}


#pragma mark - AHAAllihoopaSDKDelegate

- (void)openPieceFromAllihoopa:(AHAPiece *)piece error:(NSError *)error {
	if (piece) {
		NSLog(@"Open piece %@", piece.title);

		[piece downloadMixStemWithFormat:AHAAudioFormatOggVorbis completion:^(NSData * _Nullable data, NSError * _Nullable error) {
			NSLog(@"Got mix stem data %@", data);
		}];

		[piece downloadAudioPreviewWithFormat:AHAAudioFormatOggVorbis completion:^(NSData * _Nullable data, NSError * _Nullable error) {
			NSLog(@"Got audio preview data %@", data);
		}];

		[piece downloadCoverImage:^(UIImage * _Nullable image, NSError * _Nullable error) {
			NSLog(@"Got cover image %@", image);
		}];
	}
}


@end
