#import "AllihoopaSDK.h"

#import <AllihoopaCore/AllihoopaCore.h>

#import "Allihoopa+Internal.h"
#import "AuthenticationViewController.h"
#import "Drop/DropViewController.h"
#import "Activity.h"

@interface AHAAllihoopaSDK ()
@end

@implementation AHAAllihoopaSDK {
	AHAAuthenticationViewController* _currentAuthViewController;
}

#pragma mark - Static interface

+ (instancetype)sharedInstance {
	static AHAAllihoopaSDK* instance = nil;
	static dispatch_once_t onceToken;

	dispatch_once(&onceToken, ^{
		instance = [[AHAAllihoopaSDK alloc] init];
	});

	NSAssert(instance, @"Could not construct the AHAAllihoopaSDK instance");

	return instance;
}


- (void)validateURLSchemeSetup {
	NSBundle* bundle = [NSBundle mainBundle];
	NSString* expectedURLScheme = [NSString stringWithFormat:@"ah-%@", self.currentConfiguration.applicationIdentifier];

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
    [self authenticateUsingAuthenticationType:AHAAuthenticationTypeNone completion:completion];
}

- (void)authenticateUsingAuthenticationType:(AHAAuthenticationType)authenticationType
                                 completion:(AHAAuthenticationCallback)completion {
    if (!completion) {
        AHARaiseInvalidUsageException(@"You must provide a completion handler to the authenticate method");
    }

    NSAssert(_currentAuthViewController == nil, @"Only one auth session can be active");

    [((AHABaseAllihoopaSDK*)self) validateStoredAccessToken:^(BOOL successful) {
        if (successful) {
            completion(YES);
        }
        else {
            AHALog(@"No access token found, showing auth view controller");
            AHAAuthenticationViewController* authController = [[AHAAuthenticationViewController alloc]
                                                               initWithConfiguration:self.currentConfiguration
                                                               authenticationType:authenticationType
                                                               completionHandler:^(BOOL innerSuccessful) {
                                                                   self->_currentAuthViewController = nil;
                                                                   completion(innerSuccessful);
                                                               }];

            authController.modalPresentationStyle = UIModalPresentationFormSheet;

            UIWindow* newWindow = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
            newWindow.rootViewController = [[UIViewController alloc] init];
            [newWindow makeKeyAndVisible];
            [newWindow.rootViewController presentViewController:authController animated:YES completion:nil];

            self->_currentAuthViewController = authController;
        }
    }];
}

- (BOOL)handleOpenURL:(NSURL* _Nonnull)url {
	if ([super handleOpenURL:url]) {
		NSString* command = url.host;

		if ([command isEqualToString:@"authorize"]) {
			[_currentAuthViewController handleOpenURL:url];
		}

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
	dropFlow.configuration = self.currentConfiguration;
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
