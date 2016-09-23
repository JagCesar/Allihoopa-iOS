//
//  AHAAllihoopaSDK.m
//  Allihoopa
//
//  Created by Magnus Hallin on 23/09/16.
//  Copyright © 2016 Allihoopa. All rights reserved.
//

@import SafariServices;

static NSString* const kInfoPlistAppKey = @"AllihoopaSDKAppKey";
static NSString* const kInfoPlistAppSecret = @"AllihoopaSDKAppSecret";

#import "AllihoopaSDK.h"

@interface AHAAllihoopaSDK () <SFSafariViewControllerDelegate>
@end

@implementation AHAAllihoopaSDK {
	NSString* _configuredAppKey;
	NSString* _configuredAppSecret;

	AHAAuthenticationCallback _currentAuthCallback;
	SFSafariViewController* _currentAuthViewController;
}

+ (void)setup {
	[[self sharedInstance] setup];
}

+ (void)authenticate:(void (^)(BOOL))completion {
	[[self sharedInstance] authenticate:completion];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
	return [[self sharedInstance] handleOpenURL:url];
}

+ (instancetype)sharedInstance {
	static AHAAllihoopaSDK* instance = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		instance = [[AHAAllihoopaSDK alloc] init];
	});

	return instance;
}


- (void)setup {
	NSAssert(_configuredAppKey == nil && _configuredAppSecret == nil, @"The Allihoopa SDK can only be configured once");

	NSBundle* bundle = [NSBundle mainBundle];
	NSString* appKey = [bundle objectForInfoDictionaryKey:kInfoPlistAppKey];
	NSString* appSecret = [bundle objectForInfoDictionaryKey:kInfoPlistAppSecret];

	NSAssert(appKey != nil && appKey.length > 0, @"The %@ key in your Info.plist must be set to your Allihoopa app key", kInfoPlistAppKey);
	NSAssert(appSecret != nil && appSecret.length > 0, @"The %@ key in your Info.plist must be set to your Allihoopa app secret", kInfoPlistAppSecret);

	_configuredAppKey = [appKey copy];
	_configuredAppSecret = [appSecret copy];
}

- (void)authenticate:(void (^)(BOOL))completion {
	NSAssert(_configuredAppKey != nil,
			 @"The Allihoopa SDK has not been configured yet, call +[AHAAllihoopaSDK setupWithAppKey:secret:] before using other methods");
	NSAssert(completion != nil,
			 @"You must provide a completion handler to the authenticate method");

	NSAssert(_currentAuthCallback == nil && _currentAuthViewController == nil,
			 @"Internal error: only one auth session can be active");

	NSString* url = [NSString stringWithFormat:@"https://allihoopa.com/account/login?response_type=token&client_id=%@", _configuredAppKey];

	SFSafariViewController* safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
	safari.modalPresentationStyle = UIModalPresentationFormSheet;
	safari.delegate = self;

	UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;

	[rootController presentViewController:safari animated:YES completion:nil];

	_currentAuthCallback = completion;
	_currentAuthViewController = safari;
}

- (BOOL)handleOpenURL:(NSURL* _Nonnull)url {
	NSAssert(_configuredAppKey != nil, @"The Allihoopa SDK has not been configured yet, call +[AHAAllihoopaSDK setupWithAppKey:secret:] before using other methods");

	NSString* scheme = [NSString stringWithFormat:@"ph-%@", _configuredAppKey];

	if (![url.scheme isEqualToString:scheme]) {
		return NO;
	}

	if (_currentAuthCallback) {
		NSAssert(_currentAuthViewController != nil, @"Internal error: expected auth view controller");

		AHAAuthenticationCallback callback = _currentAuthCallback;
		SFSafariViewController* safari = _currentAuthViewController;

		_currentAuthCallback = nil;
		_currentAuthViewController = nil;

		[safari dismissViewControllerAnimated:YES completion:^{
			callback(YES);
		}];
	}

	return YES;
}



#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(__unused SFSafariViewController *)controller {
	if (_currentAuthCallback == nil) {
		return;
	}

	AHAAuthenticationCallback callback = _currentAuthCallback;
	_currentAuthCallback = nil;
	_currentAuthViewController = nil;

	callback(NO);
}

@end
