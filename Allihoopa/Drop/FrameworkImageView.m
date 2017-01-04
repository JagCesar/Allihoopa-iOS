#import "FrameworkImageView.h"

#import <AllihoopaCore/AllihoopaCore.h>

@implementation AHAFrameworkImageView

- (void)setImageName:(NSString *)imageName {
	NSURL* cocoaPodsBundleURL = [[NSBundle bundleForClass:[AHABaseAllihoopaSDK class]] URLForResource:@"AllihoopaCore" withExtension:@"bundle"];
	NSBundle* assetBundle;

	if (cocoaPodsBundleURL) {
		assetBundle = [NSBundle bundleWithURL:cocoaPodsBundleURL];
	}

	if (!assetBundle) {
		assetBundle = [NSBundle bundleForClass:[AHABaseAllihoopaSDK class]];
	}

	self.image = [UIImage imageNamed:imageName
							inBundle:assetBundle
	   compatibleWithTraitCollection:nil];
}

@end
