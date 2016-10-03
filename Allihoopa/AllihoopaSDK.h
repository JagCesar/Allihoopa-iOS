@import UIKit;

typedef void (^AHAAuthenticationCallback)(BOOL successful);

#import "DropPieceData.h"
#import "DropDelegate.h"

@interface AHAAllihoopaSDK : NSObject

/**
 Initialize the SDK and perform some basic sanity checking
 
 This requires that the AllihoopaSDKAppKey and AllihoopaSDKAppSecret values
 have been set in the application's Info.plist. It also requires that the
 `ah-{applicationIdentifier}` URL scheme has been registered. +setup will throw
 an exception if any of these conditions have not been met.
 */
+ (void)setup;

+ (void)authenticate:(AHAAuthenticationCallback _Nonnull)completion;

+ (BOOL)handleOpenURL:(NSURL* _Nonnull)url;

+ (UIViewController* _Nonnull)dropViewControllerForPiece:(AHADropPieceData* _Nonnull)dropPieceData
												delegate:(id<AHADropDelegate> _Nonnull)delegate;

+ (UIActivity* _Nonnull)activityForPiece:(AHADropPieceData* _Nonnull)dropPieceData
								delegate:(id<AHADropDelegate> _Nonnull)delegate;

@end
