#import <AllihoopaCore/BaseAllihoopaSDK.h>

@protocol AHADropDelegate;

@interface AHAAllihoopaSDK : AHABaseAllihoopaSDK

+ (AHAAllihoopaSDK* _Nonnull)sharedInstance NS_SWIFT_NAME(shared());

/**
 Ensure that the user is authenticated
 
 This opens a modal view controller with a log in screen if necessary. The
 completion callback is called with a boolean that determines whether the user
 actually become logged in or not.

 You *probably* don't need to call this method directly - it is automatically
 called before a user can drop.
 */
- (void)authenticate:(AHAAuthenticationCallback _Nonnull)completion;

/**
 Create a view controller to drop a piece

 Present this view controller modally to start the drop flow. The user will be
 asked to log in if they haven't already. Both arguments are required. The
 delegate will be notified when the drop process is complete.
 */
- (UIViewController* _Nonnull)dropViewControllerForPiece:(AHADropPieceData* _Nonnull)dropPieceData
												delegate:(id<AHADropDelegate> _Nonnull)delegate;

/**
 Create a UIActivity to drop a piece

 This can be used together with the `UIActivityViewController` to present a
 share screen that includes Allihoopa. It has the same requirements as
 `dropViewControllerForPiece:delegate:`.
 */
- (UIActivity* _Nonnull)activityForPiece:(AHADropPieceData* _Nonnull)dropPieceData
								delegate:(id<AHADropDelegate> _Nonnull)delegate;

@end
