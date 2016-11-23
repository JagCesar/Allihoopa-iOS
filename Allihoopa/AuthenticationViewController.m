#import <SafariServices/SafariServices.h>

#import "AuthenticationViewController.h"

#import "Allihoopa+Internal.h"
#import "Configuration.h"


@interface AHAAuthenticationViewController () <SFSafariViewControllerDelegate> {
	AHAAuthenticationControllerCallback _completionHandler;
	AHAConfiguration* _configuration;
	SFSafariViewController* _safari;
}
@end


@implementation AHAAuthenticationViewController

#pragma mark - Lifecycle

- (instancetype)initWithConfiguration:(AHAConfiguration *)configuration
					completionHandler:(AHAAuthenticationControllerCallback)completionHandler {
	if ((self = [super init])) {
		_completionHandler = completionHandler;
		_configuration = configuration;
	}

	return self;
}

- (void)viewDidLoad {
	NSString* url = [NSString
					 stringWithFormat:(WEB_BASE_URL @"/account/login?response_type=token&client_id=%@&allow_popups=false"),
					 _configuration.applicationIdentifier];

	SFSafariViewController* safari = [[SFSafariViewController alloc] initWithURL:[NSURL URLWithString:url]];
	[self addChildViewController:safari];
	[self.view addSubview:safari.view];

	safari.view.frame = self.view.bounds;
	safari.delegate = self;

	_safari = safari;
}

- (void)viewDidLayoutSubviews {
	_safari.view.frame = self.view.bounds;
}

- (void)dealloc {
	AHALog(@"Deallocing AHAAuthenticationViewController");
}

#pragma mark - Public interface

- (BOOL)handleOpenURL:(NSURL *)url {
	NSString* scheme = [NSString stringWithFormat:@"ah-%@", _configuration.applicationIdentifier];

	if (![url.scheme isEqualToString:scheme]) {
		return NO;
	}

	if (_completionHandler) {
		NSAssert(_safari != nil, @"Expected auth view controller");

		AHAAuthenticationControllerCallback callback = _completionHandler;
		SFSafariViewController* safari = _safari;

		_completionHandler = nil;
		_safari = nil;

		[safari dismissViewControllerAnimated:YES completion:^{
			[self parseAndSaveCredentials:url];
			callback(YES);
		}];
	}

	return YES;
}

#pragma mark - SFSafariViewControllerDelegate

- (void)safariViewControllerDidFinish:(__unused SFSafariViewController*)controller {
	if (_completionHandler == nil) {
		return;
	}

	AHAAuthenticationControllerCallback callback = _completionHandler;
	[self clearSavedCredentials];
	_completionHandler = nil;
	_safari = nil;

	callback(NO);
}

#pragma mark - Private methods (Access token saving)

- (void)parseAndSaveCredentials:(NSURL* _Nonnull)url {
	NSAssert(url != nil, @"Must provide url");

	NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	NSString* accessToken;

	for (NSURLQueryItem* item in components.queryItems) {
		if ([item.name isEqualToString:@"access_token"]) {
			accessToken = item.value;
		}
	}

	NSAssert(accessToken != nil, @"No access_token parameter was supplied");

	_configuration.accessToken = accessToken;

}

- (void)clearSavedCredentials {
	_configuration.accessToken = nil;
}


@end
