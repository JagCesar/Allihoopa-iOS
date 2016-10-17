@import UIKit;

@class AHADropDoneViewController;

@protocol AHADropProgressViewControllerDelegate <NSObject>
@required

- (void)dropProgressViewControllerWillSegueToDoneViewController:(AHADropDoneViewController*)dropDoneViewController;

@end

@interface AHADropProgressViewController : UIViewController

@property (weak, nonatomic) id<AHADropProgressViewControllerDelegate> dropProgressDelegate;

- (void)advanceToDropDone;

@end
