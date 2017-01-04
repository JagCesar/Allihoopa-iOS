#import <UIKit/UIKit.h>

#import <AllihoopaCore/BaseDropDelegate.h>

@protocol AHADropDelegate <AHABaseDropDelegate>

@optional
- (void)dropViewController:(UIViewController* _Nonnull)sender
		 forPieceWillClose:(AHADropPieceData* _Nonnull)piece
	   afterSuccessfulDrop:(BOOL)successfulDrop
NS_SWIFT_NAME(dropViewController(_:willClose:successfulDrop:));

@end
