#import "DropProgressViewController.h"

#import "DropDoneViewController.h"

@interface AHADropProgressViewController ()
@property (strong, nonatomic) IBOutlet UIView *warningContainer;

@end

@implementation AHADropProgressViewController

- (void)viewDidLoad {
	NSAssert(_dropProgressDelegate != nil, @"Drop progress delegate must be set");

	_warningContainer.layer.shadowColor = [UIColor blackColor].CGColor;
	_warningContainer.layer.shadowOffset = CGSizeMake(0, 0);
	_warningContainer.layer.shadowRadius = 10;
	_warningContainer.layer.shadowOpacity = 0.13f;

	_warningContainer.layer.borderColor = [UIColor colorWithWhite:0 alpha:0.09f].CGColor;
	_warningContainer.layer.borderWidth = 1;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(__unused id)sender {
	if ([segue.identifier isEqualToString:@"dropProgressDone"]) {
		AHADropDoneViewController* destination = segue.destinationViewController;
		NSAssert([destination isKindOfClass:[AHADropDoneViewController class]],
				 @"dropProgressDone segue must go to drop done view controller");

		[_dropProgressDelegate dropProgressViewControllerWillSegueToDoneViewController:destination];
	}
}

- (void)advanceToDropDone {
	[self performSegueWithIdentifier:@"dropProgressDone" sender:nil];
}

@end
