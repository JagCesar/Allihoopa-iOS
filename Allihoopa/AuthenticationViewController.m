#import <SafariServices/SafariServices.h>

#import <AllihoopaCore/AllihoopaCore.h>
#import "AllihoopaSDK.h"

#import "AuthenticationViewController.h"

#import "Allihoopa+Internal.h"


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
	NSURL* url = [[AHAAllihoopaSDK sharedInstance] authenticationURLAllowingPopups:NO];

	SFSafariViewController* safari = [[SFSafariViewController alloc] initWithURL:url];
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

- (void)clearSavedCredentials {
	_configuration.accessToken = nil;
}


@end
