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

+ (void)setupWithApplicationIdentifier:(NSString*)applicationIdentifier apiKey:(NSString*)apiKey {
	[[self sharedInstance] setupWithApplicationIdentifier:applicationIdentifier apiKey:apiKey];
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


- (void)setupWithApplicationIdentifier:(NSString*)applicationIdentifier apiKey:(NSString*)apiKey {
	if (applicationIdentifier == nil || applicationIdentifier.length == 0) {
		AHARaiseInvalidUsageException(@"No application identifier provided");
	}

	if (apiKey == nil || apiKey.length == 0) {
		AHARaiseInvalidUsageException(@"No API key provided");
	}

	[_configuration setupApplicationIdentifier:applicationIdentifier apiKey:apiKey];

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

	UIWindow* newWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	newWindow.rootViewController = [[UIViewController alloc] init];
	[newWindow makeKeyAndVisible];
	[newWindow.rootViewController presentViewController:authController animated:YES completion:nil];


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
	return [[AHAActivity alloc] initWithPiece:dropPieceData delegate:delegate];
}

@end
