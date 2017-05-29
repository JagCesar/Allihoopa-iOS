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
	NSString* facebookAppID = [mainBundle objectForInfoDictionaryKey:@"AllihoopaSDKFacebookAppID"];

	NSMutableDictionary* config = [@{
									 AHAConfigKeyApplicationIdentifier: applicationIdentifier,
									 AHAConfigKeyAPIKey: apiKey,
									 AHAConfigKeySDKDelegate: self,
									 } mutableCopy];

	if (facebookAppID != nil) {
		[config setObject:facebookAppID forKey:AHAConfigKeyFacebookAppID];
	}

	[[AHAAllihoopaSDK sharedInstance] setupWithConfiguration:config];
}

- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options {
	if ([[AHAAllihoopaSDK sharedInstance] handleOpenURL:url]) {
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

		[piece downloadAttachment:@"application/figure" completion:^(NSData * _Nullable data, NSError * _Nullable error) {
			NSLog(@"Got attachment data %@", data);
		}];
	}
}


@end
