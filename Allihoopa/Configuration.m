#import "Configuration.h"

static NSString* const kConfigurationDefaultsKey = @"allihoopa-sdk-prefs";

static NSString* const kConfigKeyAccessToken = @"access-token";

@implementation AHAConfiguration {
	NSString* _applicationIdentifier;
	NSString* _apiKey;
}

- (void)setupApplicationIdentifier:(NSString *)applicationIdentifier apiKey:(NSString *)apiKey {
	NSAssert(applicationIdentifier != nil,
			 @"Internal error: application identifier must be non-nil");
	NSAssert(apiKey != nil,
			 @"Internal error: API key must be non-nil");

	_applicationIdentifier = applicationIdentifier;
	_apiKey = apiKey;
}

- (NSDictionary<NSString *,id> *)configuration {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	NSDictionary* config = [defaults dictionaryForKey:kConfigurationDefaultsKey];
	if (!config) {
		config = [NSDictionary dictionary];
	}

	return config;
}

- (void)update:(void (^ _Nonnull)(NSMutableDictionary<NSString*,id>* _Nonnull configuration))updateBlock {
	NSUserDefaults* defaults = [NSUserDefaults standardUserDefaults];

	NSMutableDictionary* config = [[defaults dictionaryForKey:kConfigurationDefaultsKey] mutableCopy];
	if (config == nil) {
		config = [[NSMutableDictionary alloc] init];
	}

	updateBlock(config);

	[defaults setObject:config forKey:kConfigurationDefaultsKey];
	[defaults synchronize];
}

- (NSString *)applicationIdentifier {
	NSAssert(_applicationIdentifier != nil,
			 @"The Allihoopa SDK has not been configured yet, call +[AHAAllihoopaSDK setup] before using other methods");

	return _applicationIdentifier;
}

- (NSString *)apiKey {
	NSAssert(_apiKey != nil,
			 @"The Allihoopa SDK has not been configured yet, call +[AHAAllihoopaSDK setup] before using other methods");

	return _apiKey;
}

- (void)setAccessToken:(NSString *)accessToken {
	[self update:^(NSMutableDictionary<NSString *,id> * _Nonnull configuration) {
		if (accessToken != nil) {
			configuration[kConfigKeyAccessToken] = accessToken;
		}
		else {
			[configuration removeObjectForKey:kConfigKeyAccessToken];
		}
	}];
}

- (NSString *)accessToken {
	return self.configuration[kConfigKeyAccessToken];
}

@end
