#import "AllihoopaSDK.h"

#import "Configuration.h"
#import "AuthenticationViewController.h"
#import "Drop/DropViewController.h"
#import "Activity.h"
#import "Errors.h"

static NSString* const kInfoPlistAppKey = @"AllihoopaSDKAppKey";
static NSString* const kInfoPlistAppSecret = @"AllihoopaSDKAppSecret";

@interface AHAAllihoopaSDK ()
@end

@implementation AHAAllihoopaSDK {
	AHAAuthenticationViewController* _currentAuthViewController;

	AHAConfiguration* _configuration;
}

#pragma mark - Static interface

+ (void)setup {
	[[self sharedInstance] setup];
}

+ (void)authenticate:(void (^)(BOOL))completion {
	[[self sharedInstance] authenticate:completion];
}

+ (BOOL)handleOpenURL:(NSURL *)url {
	return [[self sharedInstance] handleOpenURL:url];
}

+ (UIViewController *)dropViewControllerForPiece:(AHADropPieceData *)dropPieceData delegate:(id<AHADropDelegate>)delegate {
	return [[self sharedInstance] dropViewControllerForPiece:dropPieceData delegate:delegate];
}

+ (UIActivity *)activityForPiece:(AHADropPieceData *)dropPieceData delegate:(id<AHADropDelegate>)delegate {
	return [[self sharedInstance] activityForPiece:dropPieceData delegate:delegate];
}

+ (instancetype)sharedInstance {
	static AHAAllihoopaSDK* instance = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		instance = [[AHAAllihoopaSDK alloc] init];
	});

	NSAssert(instance, @"Could not construct the AHAAllihoopaSDK instance");

	return instance;
}

#pragma mark - Initialization

- (instancetype)init {
	if ((self = [super init])) {
		_configuration = [[AHAConfiguration alloc] init];
	}

	return self;
}

#pragma mark - Private methods (non-static counterparts)


- (void)setup {
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* appKey = [bundle objectForInfoDictionaryKey:kInfoPlistAppKey];
	NSString* appSecret = [bundle objectForInfoDictionaryKey:kInfoPlistAppSecret];

	if (appKey == nil || appKey.length == 0) {
		AHARaiseInvalidUsageException(@"The %@ key in your Info.plist must be set to your Allihoopa app key", kInfoPlistAppKey);
	}

	if (appSecret == nil || appSecret.length == 0) {
		AHARaiseInvalidUsageException(@"The %@ key in your Info.plist must be set to your Allihoopa app secret", kInfoPlistAppSecret);
	}

	[_configuration setupApplicationIdentifier:appKey apiKey:appSecret];

	[self validateURLSchemeSetup];
}

- (void)validateURLSchemeSetup {
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* expectedURLScheme = [NSString stringWithFormat:@"ah-%@", _configuration.applicationIdentifier];

	NSDictionary<NSString*,id>* bundleURLTypes = [bundle objectForInfoDictionaryKey:@"CFBundleURLTypes"];
	BOOL foundScheme = NO;

	// Sanity check that the URL scheme has been registered
	for (NSDictionary<NSString*,id>* urlType in bundleURLTypes) {
		NSArray* urlSchemes = urlType[@"CFBundleURLSchemes"];

		if ([urlSchemes indexOfObject:expectedURLScheme] != NSNotFound) {
			foundScheme = YES;
		}
	}

	if (!foundScheme) {
		AHARaiseInvalidUsageException(@"The %@ URL scheme must be registered in your Info.plist for the Allihoopa SDK to work", expectedURLScheme);
	}
}

- (void)authenticate:(void (^)(BOOL))completion {
	if (!completion) {
		AHARaiseInvalidUsageException(@"You must provide a completion handler to the authenticate method");
	}

	NSAssert(_currentAuthViewController == nil, @"Only one auth session can be active");

	__weak AHAAllihoopaSDK* weakSelf = self;
	AHAAuthenticationViewController* authController = [[AHAAuthenticationViewController alloc]
													   initWithConfiguration:_configuration
													   completionHandler:^(BOOL successful) {
														   AHAAllihoopaSDK* strongSelf = weakSelf;
														   if (strongSelf) {
															   strongSelf->_currentAuthViewController = nil;
														   }

														   completion(successful);
													   }];

	authController.modalPresentationStyle = UIModalPresentationFormSheet;

	UIViewController* rootController = [UIApplication sharedApplication].keyWindow.rootViewController;

	[rootController presentViewController:authController animated:YES completion:nil];

	_currentAuthViewController = authController;
}

- (BOOL)handleOpenURL:(NSURL* _Nonnull)url {
	return [_currentAuthViewController handleOpenURL:url];
}

- (UIViewController *)dropViewControllerForPiece:(AHADropPieceData *)dropPieceData
										delegate:(id<AHADropDelegate>)delegate {
	UIStoryboard* storyboard = [UIStoryboard
								storyboardWithName:@"DropFlow"
								bundle:[NSBundle bundleForClass:[AHAAllihoopaSDK class]]];
	AHADropViewController* dropFlow = [storyboard instantiateInitialViewController];
	NSAssert(dropFlow && [dropFlow isKindOfClass:[AHADropViewController class]],
			 @"DropFlow storyboard must have an AHADropViewController as its initial view controller");
	dropFlow.configuration = _configuration;
	dropFlow.dropDelegate = delegate;
	dropFlow.dropPieceData = dropPieceData;
	dropFlow.modalPresentationStyle = UIModalPresentationFormSheet;
	dropFlow.dismissWhenCloseTapped = YES;

	return dropFlow;
}

- (UIActivity *)activityForPiece:(AHADropPieceData *)dropPieceData
						delegate:(id<AHADropDelegate>)delegate {
	return [[AHAActivity alloc] init];
}

@end
