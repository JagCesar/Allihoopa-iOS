#import <UIKit/UIKit.h>

@class ACAccount;
@class ACAccountCredential;

@class AHADropProgressViewController;
@class AHAConfiguration;
@class AHADropInfo;



@protocol AHADropInfoViewControllerDelegate <NSObject>
@required

- (void)dropInfoViewControllerDidCommit:(AHADropInfo*)dropInfo;

- (void)dropInfoViewControllerWillSegueToProgressViewController:(AHADropProgressViewController*)dropProgressViewController;

@end




@interface AHADropInfoViewController : UIViewController

@property (weak, nonatomic) id<AHADropInfoViewControllerDelegate> dropInfoDelegate;
@property (strong, nonatomic) AHAConfiguration* configuration;

- (void)setDefaultTitle:(NSString*)defaultTitle;
- (void)setDefaultCoverImage:(UIImage*)defaultImage;

- (void)segueToProgressViewController;

@end
