#import <UIKit/UIKit.h>

@class ACAccount;
@class ACAccountCredential;

@class AHADropProgressViewController;
@class AHAConfiguration;

@protocol AHADropInfoViewControllerDelegate <NSObject>
@required

- (void)dropInfoViewControllerDidCommitTitle:(NSString*)title
								 description:(NSString*)description
									  listed:(BOOL)isListed
								  coverImage:(UIImage*)coverImage
							 facebookAccount:(ACAccount*)facebookAccount
				   facebookAccountCredential:(ACAccountCredential*)facebookAccountCredential
							  twitterAccount:(ACAccount*)twitterAccount;

- (void)dropInfoViewControllerWillSegueToProgressViewController:(AHADropProgressViewController*)dropProgressViewController;

@end

@interface AHADropInfoViewController : UIViewController

@property (weak, nonatomic) id<AHADropInfoViewControllerDelegate> dropInfoDelegate;
@property (strong, nonatomic) AHAConfiguration* configuration;

- (void)setDefaultTitle:(NSString*)defaultTitle;
- (void)setDefaultCoverImage:(UIImage*)defaultImage;

- (void)segueToProgressViewController;

@end
