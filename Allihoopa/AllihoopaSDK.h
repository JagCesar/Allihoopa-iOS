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
 Opens up an authentication view if the user isn't already signed in. The
 completion callback is called with a boolean that determines whether the user
 actually signed in or not.

 You can set the AuthenticationType argument to define if the user should go
 to a sign in form, sign up form or a view where both are available. If you're
 unsure of which authentication type to specify, use -authenticate: instead.
 */

- (void)authenticateUsingAuthenticationType:(AHAAuthenticationType)authenticationType
                                completion:(AHAAuthenticationCallback _Nonnull)completion;

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
