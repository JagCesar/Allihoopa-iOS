#import "DropProgressViewController.h"

@implementation AHADropProgressViewController

- (void)advanceToDropDone {
	[self performSegueWithIdentifier:@"dropProgressDone" sender:nil];
}

- (void)advanceToDropError {
	[self performSegueWithIdentifier:@"dropError" sender:nil];
}

@end
