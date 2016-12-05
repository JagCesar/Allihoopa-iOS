#import "Configuration.h"
#import "Errors.h"

static NSString* const kConfigurationDefaultsKey = @"allihoopa-sdk-prefs";

static NSString* const kConfigKeyAccessToken = @"access-token";

@implementation AHAConfiguration {
	NSString* _applicationIdentifier;
	NSString* _apiKey;
	NSString* _facebookAppID;
}

- (void)setupApplicationIdentifier:(NSString*)applicationIdentifier
							apiKey:(NSString*)apiKey
					 facebookAppID:(NSString*)facebookAppID {
	NSAssert(applicationIdentifier != nil, @"Application identifier must be non-nil");
	NSAssert(apiKey != nil, @"API key must be non-nil");

	_applicationIdentifier = [applicationIdentifier copy];
	_apiKey = [apiKey copy];
	_facebookAppID = [facebookAppID copy];
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

- (NSString*)applicationIdentifier {
	if (!_applicationIdentifier) {
		AHARaiseInvalidUsageException(@"The Allihoopa SDK has not been configured yet, call +[AHAAllihoopaSDK setup] before using other methods");
	}

	return _applicationIdentifier;
}

- (NSString*)apiKey {
	if (!_apiKey) {
		AHARaiseInvalidUsageException(@"The Allihoopa SDK has not been configured yet, call +[AHAAllihoopaSDK setup] before using other methods");
	}

	return _apiKey;
}

- (NSString*)facebookAppID {
	return _facebookAppID;
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
