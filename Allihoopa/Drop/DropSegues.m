#import "DropSegues.h"

@implementation AHADropErrorSegue

- (void)perform {
	UINavigationController* source = self.sourceViewController;
	UIViewController* destination = self.destinationViewController;
	NSAssert([source isKindOfClass:[UINavigationController class]],
			 @"Source must have navigation controller attached");

	[source setViewControllers:@[ destination ] animated:YES];
}

@end
