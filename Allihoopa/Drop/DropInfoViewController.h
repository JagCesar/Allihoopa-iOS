@import UIKit;

@class AHADropProgressViewController;

@protocol AHADropInfoViewControllerDelegate <NSObject>
@required

- (void)dropInfoViewControllerDidCommitTitle:(NSString*)title
								 description:(NSString*)description
									  listed:(BOOL)isListed
								  coverImage:(UIImage*)coverImage;

- (void)dropInfoViewControllerWillSegueToProgressViewController:(AHADropProgressViewController*)dropProgressViewController;

@end

@interface AHADropInfoViewController : UITableViewController

@property (weak, nonatomic) id<AHADropInfoViewControllerDelegate> dropInfoDelegate;

- (void)setDefaultTitle:(NSString*)defaultTitle;
- (void)setDefaultCoverImage:(UIImage*)defaultImage;

@end
