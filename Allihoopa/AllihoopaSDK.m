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

#define WEB_BASE_URL @"https://allihoopa.com"

static NSString* const kConfigurationDefaultsKey = @"allihoopa-sdk-prefs";

static NSString* const kConfigKeyAccessToken = @"access-token";

static NSString* const kAppKey = @"app-key";
static NSString* const kAppSecretKey = @"app-secret";

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

	NSString* url = [NSString stringWithFormat:(WEB_BASE_URL @"/account/login?response_type=token&client_id=%@"), _configuredAppKey];

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

	NSString* scheme = [NSString stringWithFormat:@"ah-%@", _configuredAppKey];

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
			[self parseAndSaveCredentials:url];
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
	[self clearSavedCredentials];
	_currentAuthCallback = nil;
	_currentAuthViewController = nil;

	callback(NO);
}



#pragma mark - Private methods (Configuration)

- (void)updateConfiguration:(void (^)(NSMutableDictionary* configuration))updateBlock {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	NSMutableDictionary* config = [[defaults dictionaryForKey:kConfigurationDefaultsKey] mutableCopy];
	if (config == nil) {
		config = [[NSMutableDictionary alloc] init];
	}

	updateBlock(config);

	[defaults setObject:config forKey:kConfigurationDefaultsKey];
	[defaults synchronize];
}


#pragma mark - Private methods (Access token saving)

- (void)parseAndSaveCredentials:(NSURL* _Nonnull)url {
	NSAssert(url != nil, @"Internal error: must provide url");

	NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	NSString* accessToken;

	for (NSURLQueryItem* item in components.queryItems) {
		if ([item.name isEqualToString:@"access_token"]) {
			accessToken = item.value;
		}
	}

	NSAssert(accessToken != nil, @"Internal error: no access_token parameter was supplied");

	[self updateConfiguration:^(NSMutableDictionary *configuration) {
		[configuration setObject:accessToken forKey:kConfigKeyAccessToken];
	}];

}

- (void)clearSavedCredentials {
	[self updateConfiguration:^(NSMutableDictionary *configuration) {
		[configuration removeObjectForKey:kConfigKeyAccessToken];
	}];
}

@end
