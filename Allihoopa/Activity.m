#import "Activity.h"

#import "AllihoopaSDK.h"

@implementation AHAActivity

+ (UIActivityCategory)activityCategory {
	return UIActivityCategoryShare;
}

- (UIActivityType)activityType {
	return @"AHADropToAllihoopa";
}

- (NSString *)activityTitle {
	return @"Allihoopa";
}

- (UIImage *)activityImage {
	return nil;
}

- (BOOL)canPerformWithActivityItems:(__unused NSArray *)activityItems {
	return YES;
}

- (UIViewController *)activityViewController {
	return [AHAAllihoopaSDK dropViewControllerForPiece:nil delegate:nil];
}

@end
