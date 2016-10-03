#import "DropProgressViewController.h"

@implementation AHADropProgressViewController

- (void)advanceToDropDone {
	[self performSegueWithIdentifier:@"dropProgressDone" sender:nil];
}

@end
