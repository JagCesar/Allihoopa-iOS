#import "AllihoopaSDK.h"

#import "Allihoopa+Internal.h"
#import "Configuration.h"
#import "AuthenticationViewController.h"
#import "Drop/DropViewController.h"
#import "Activity.h"
#import "Errors.h"
#import "APICommunication.h"
#import "Piece.h"
#import "Import.h"

static NSString* const kInfoPlistAppKey = @"AllihoopaSDKAppKey";
static NSString* const kInfoPlistAppSecret = @"AllihoopaSDKAppSecret";

static NSString* const kMeGraphQLQuery = @"\
{\
  me {\
    profileUrl\
  }\
}";

@interface AHAAllihoopaSDK ()
@end

@implementation AHAAllihoopaSDK {
	AHAAuthenticationViewController* _currentAuthViewController;

	AHAConfiguration* _configuration;

	__weak id<AHAAllihoopaSDKDelegate> _delegate;
}

#pragma mark - Static interface

+ (void)setupWithApplicationIdentifier:(NSString*)applicationIdentifier
								apiKey:(NSString*)apiKey
							  delegate:(id<AHAAllihoopaSDKDelegate> _Nonnull)delegate {
	[[self sharedInstance] setupWithApplicationIdentifier:applicationIdentifier
												   apiKey:apiKey
												 delegate:delegate];
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


- (void)setupWithApplicationIdentifier:(NSString*)applicationIdentifier
								apiKey:(NSString*)apiKey
							  delegate:(id<AHAAllihoopaSDKDelegate>)delegate {
	if (applicationIdentifier == nil || applicationIdentifier.length == 0) {
		AHARaiseInvalidUsageException(@"No application identifier provided");
	}

	if (apiKey == nil || apiKey.length == 0) {
		AHARaiseInvalidUsageException(@"No API key provided");
	}

	_delegate = delegate;

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

	if (_configuration.accessToken) {
		AHALog(@"Found access token, checking if it's still valid");

		// We can let the following blocks take a strong reference to self since this is a
		// singleton instance anyway.
		AHAGraphQLQuery(_configuration, kMeGraphQLQuery, @{}, ^(NSDictionary *response, __unused NSError *error) {
			if (response && response[@"me"]) {
				AHALog(@"Access token valid, skipping auth view controller");
				completion(YES);
			}
			else {
				AHALog(@"Access token invalid, clearing and recursing");
				self->_configuration.accessToken = nil;
				[self authenticate:completion];
			}
		});
	}
	else {
		AHALog(@"No access token found, showing auth view controller");
		AHAAuthenticationViewController* authController = [[AHAAuthenticationViewController alloc]
														   initWithConfiguration:_configuration
														   completionHandler:^(BOOL successful) {
															   self->_currentAuthViewController = nil;
															   completion(successful);
														   }];

		authController.modalPresentationStyle = UIModalPresentationFormSheet;

		UIWindow* newWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
		newWindow.rootViewController = [[UIViewController alloc] init];
		[newWindow makeKeyAndVisible];
		[newWindow.rootViewController presentViewController:authController animated:YES completion:nil];

		_currentAuthViewController = authController;
	}
}

- (BOOL)handleOpenURL:(NSURL* _Nonnull)url {
	NSString* command = url.host;

	if ([command isEqualToString:@"authorize"]) {
		return [_currentAuthViewController handleOpenURL:url];
	} else if ([command isEqualToString:@"open"]) {
		[self handleImportFromURL:url];
		return YES;
	} else {
		NSLog(@"[AllihoopaSDK] WARNING: Can not handle requested URL %@", url);
	}

	return NO;
}

- (UIViewController *)dropViewControllerForPiece:(AHADropPieceData *)dropPieceData
										delegate:(id<AHADropDelegate>)delegate {
	NSURL* cocoaPodsBundleURL = [[NSBundle mainBundle] URLForResource:@"Allihoopa" withExtension:@"bundle"];
	NSBundle* assetBundle;

	if (cocoaPodsBundleURL) {
		assetBundle = [NSBundle bundleWithURL:cocoaPodsBundleURL];
	}

	if (!assetBundle) {
		assetBundle = [NSBundle bundleForClass:[AHAAllihoopaSDK class]];
	}

	UIStoryboard* storyboard = [UIStoryboard
								storyboardWithName:@"DropFlow"
								bundle:assetBundle];
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

#pragma mark - Private methods (Importing)

- (void)handleImportFromURL:(NSURL* _Nonnull)url {
	NSURLComponents* components = [NSURLComponents componentsWithURL:url resolvingAgainstBaseURL:NO];
	NSString* pieceId;

	for (NSURLQueryItem* item in components.queryItems) {
		if ([item.name isEqualToString:@"uuid"]) {
			pieceId = item.value;
		}
	}

	NSAssert(pieceId != nil, @"No uuid parameter was supplied");

	AHAFetchPieceInfo(_configuration, pieceId, ^(AHAPiece *piece, NSError *error) {
		id<AHAAllihoopaSDKDelegate> delegate = self->_delegate;

		if ([delegate respondsToSelector:@selector(openPieceFromAllihoopa:error:)]) {
			[delegate openPieceFromAllihoopa:piece error:error];
		}
	});
}

@end
