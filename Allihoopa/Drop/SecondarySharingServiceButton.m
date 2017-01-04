#import "SecondarySharingServiceButton.h"

#import <AllihoopaCore/AllihoopaCore.h>

static NSString* const kFacebook = @"FACEBOOK";
static NSString* const kTwitter = @"TWITTER";

@implementation AHASecondarySharingServiceButton

- (void)layoutSubviews {
	[super layoutSubviews];
	if (_accountType == nil) {
		return;
	}

	UIColor* color;

	if ([_accountType isEqualToString:kFacebook]) {
		color = [UIColor colorWithRed:(CGFloat)0.24 green:(CGFloat)0.35 blue:(CGFloat)0.59 alpha:1.0];
	}
	else if ([_accountType isEqualToString:kTwitter]) {
		color = [UIColor colorWithRed:(CGFloat)0.00 green:(CGFloat)0.67 blue:(CGFloat)0.93 alpha:1.0];
	}
	else {
		NSAssert(NO, @"Unsupported account type");
	}

	NSAssert(color != nil, @"No color set");

	if (self.isSelected) {
		self.backgroundColor = color;
		self.layer.borderColor = color.CGColor;
		self.imageView.tintColor = [UIColor colorWithWhite:1.0 alpha:1.0];
	}
	else {
		self.backgroundColor = [UIColor clearColor];
		self.layer.borderColor = [UIColor colorWithWhite:(CGFloat)0.61 alpha:1.0].CGColor;
		self.imageView.tintColor = [UIColor colorWithWhite:(CGFloat)0.61 alpha:1.0];
	}

	self.layer.cornerRadius = self.frame.size.width / 2;
	self.layer.borderWidth = 1;
}

- (void)setAccountType:(NSString *)accountType {
	NSAssert(accountType != nil, @"Account type must be provided");

	_accountType = accountType;

	UIImage* image;

	if ([_accountType isEqualToString:kFacebook]) {
		image = [UIImage imageNamed:@"AHASocialIconFacebook"
						   inBundle:[NSBundle bundleForClass:[AHABaseAllihoopaSDK class]]
	  compatibleWithTraitCollection:nil];
	}
	else if ([_accountType isEqualToString:kTwitter]) {
		image = [UIImage imageNamed:@"AHASocialIconTwitter"
						   inBundle:[NSBundle bundleForClass:[AHABaseAllihoopaSDK class]]
	  compatibleWithTraitCollection:nil];
	}
	else {
		NSAssert(NO, @"Unsupported account type");
	}

	NSAssert(image != nil, @"No image found for social button");

	[self setImage:[image imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate] forState:UIControlStateNormal];

	[self setNeedsLayout];
}

@end
