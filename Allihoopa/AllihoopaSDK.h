@import UIKit;

@class AHAPiece;

typedef void (^AHAAuthenticationCallback)(BOOL successful);

#import "DropPieceData.h"
#import "DropDelegate.h"

@protocol AHAAllihoopaSDKDelegate <NSObject>

- (void)openPieceFromAllihoopa:(AHAPiece* _Nullable)piece error:(NSError* _Nullable)error;

@end

@interface AHAAllihoopaSDK : NSObject

/**
 Initialize the SDK and perform some basic sanity checking

 It also requires that the `ah-{applicationIdentifier}` URL scheme has been
 registered. will throw an exception if any of these conditions have not been
 met.
 
 @throws AHAInvalidUsageException When the application is incorrectly configured
 */
+ (void)setupWithApplicationIdentifier:(NSString* _Nonnull)applicationIdentifier
								apiKey:(NSString* _Nonnull)apiKey
							  delegate:(id<AHAAllihoopaSDKDelegate> _Nonnull)delegate NS_SWIFT_NAME(setup(applicationIdentifier:apiKey:delegate:));

/**
 Ensure that the user is authenticated
 
 This opens a modal view controller with a log in screen if necessary. The
 completion callback is called with a boolean that determines whether the user
 actually become logged in or not.

 You *probably* don't need to call this method directly - it is automatically
 called before a user can drop.
 */
+ (void)authenticate:(AHAAuthenticationCallback _Nonnull)completion;

/**
 Handle an open URL request from `UIApplicationDelegate`

 This *must* be called from your app delegate's `application:openURL:options`
 method for log in and sign up to work.
 */
+ (BOOL)handleOpenURL:(NSURL* _Nonnull)url;

/**
 Create a view controller to drop a piece

 Present this view controller modally to start the drop flow. The user will be
 asked to log in if they haven't already. Both arguments are required. The
 delegate will be notified when the drop process is complete.
 */
+ (UIViewController* _Nonnull)dropViewControllerForPiece:(AHADropPieceData* _Nonnull)dropPieceData
												delegate:(id<AHADropDelegate> _Nonnull)delegate;

/**
 Create a UIActivity to drop a piece

 This can be used together with the `UIActivityViewController` to present a
 share screen that includes Allihoopa. It has the same requirements as
 `dropViewControllerForPiece:delegate:`.
 */
+ (UIActivity* _Nonnull)activityForPiece:(AHADropPieceData* _Nonnull)dropPieceData
								delegate:(id<AHADropDelegate> _Nonnull)delegate;

@end
