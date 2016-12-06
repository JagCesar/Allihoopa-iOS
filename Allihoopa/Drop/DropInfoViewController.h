#import <UIKit/UIKit.h>

@class ACAccount;
@class ACAccountCredential;

@class AHADropProgressViewController;
@class AHAConfiguration;



@interface AHADropInfo : NSObject

@property (nonatomic, readonly) NSString* title;
@property (nonatomic, readonly) NSString* pieceDescription;
@property (nonatomic, readonly) BOOL isListed;
@property (nonatomic, readonly) UIImage* coverImage;
@property (nonatomic, readonly) ACAccount* facebookAccount;
@property (nonatomic, readonly) ACAccountCredential* facebookAccountCredential;
@property (nonatomic, readonly) ACAccount* twitterAccount;

- (instancetype)initWithTitle:(NSString*)title
			 pieceDescription:(NSString*)pieceDescription
					   listed:(BOOL)isListed
				   coverImage:(UIImage*)coverImage
			  facebookAccount:(ACAccount*)facebookAccount
	facebookAccountCredential:(ACAccountCredential*)facebookAccountCredential
			   twitterAccount:(ACAccount*)twitterAccount;

@end




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
