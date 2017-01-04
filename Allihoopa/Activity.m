#import "Activity.h"

#import "AllihoopaSDK.h"
#import "DropDelegate.h"

#import "Drop/DropViewController.h"

@interface AHAActivityProxyDropDelegate : NSObject <AHADropDelegate>

- (instancetype)initWithDelegate:(id<AHADropDelegate>)delegate activity:(AHAActivity*)activity;

@end

@implementation AHAActivity {
	AHADropPieceData* _dropPieceData;
	AHAActivityProxyDropDelegate* _dropDelegate;
}

- (instancetype)initWithPiece:(AHADropPieceData *)dropPieceData
					 delegate:(id<AHADropDelegate>)delegate {
	if ((self = [super init])) {
		NSAssert(dropPieceData != nil, @"Must provide a piece to drop");
		NSAssert(delegate != nil, @"Must provide drop delegate");

		_dropPieceData = dropPieceData;
		_dropDelegate = [[AHAActivityProxyDropDelegate alloc] initWithDelegate:delegate activity:self];
	}

	return self;
}

+ (UIActivityCategory)activityCategory {
	return UIActivityCategoryShare;
}

- (NSString*)activityType {
	return @"AHADropToAllihoopa";
}

- (NSString*)activityTitle {
	return @"Allihoopa";
}

- (UIImage*)activityImage {
	// Draw Allihoopa logotype on a white background with 40px padding
	UIGraphicsBeginImageContextWithOptions(CGSizeMake(240, 240), YES, [UIScreen mainScreen].scale);

	[[UIColor whiteColor] setFill];
	[[UIBezierPath bezierPathWithRect:CGRectMake(0, 0, 240, 240)] fill];

	UIImage* logoMark = [UIImage imageNamed:@"AHALogoMarkColor"
								   inBundle:[NSBundle bundleForClass:[AHABaseAllihoopaSDK class]]
			  compatibleWithTraitCollection:nil];
	NSAssert(logoMark != nil, @"Missing LogoMarkColor image");

	[logoMark drawInRect:CGRectMake(40, 40, 160, 160) blendMode:kCGBlendModeNormal alpha:1.0];

	UIImage* image = UIGraphicsGetImageFromCurrentImageContext();
	NSAssert(image != nil, @"Could not render logo image");

	UIGraphicsEndImageContext();

	return image;
}

- (BOOL)canPerformWithActivityItems:(__unused NSArray*)activityItems {
	return YES;
}

- (UIViewController *)activityViewController {
	UIViewController* controller = [[AHAAllihoopaSDK sharedInstance] dropViewControllerForPiece:_dropPieceData
																					   delegate:_dropDelegate];

	NSAssert([controller isKindOfClass:[AHADropViewController class]],
			 @"Expected AHADropViewController");

	AHADropViewController* dropController = (AHADropViewController*)controller;
	dropController.dismissWhenCloseTapped = NO;

	return dropController;
}

@end


@implementation AHAActivityProxyDropDelegate {
	id<AHADropDelegate> _innerDelegate;
	__weak AHAActivity* _activity;
}

- (instancetype)initWithDelegate:(id<AHADropDelegate>)delegate activity:(AHAActivity *)activity {
	if ((self = [super init])) {
		NSAssert(delegate != nil, @"Drop delegate must be provided");
		NSAssert(activity != nil, @"Owning AHAActivity must be provided");

		_innerDelegate = delegate;
		_activity = activity;
	}

	return self;
}

#pragma mark - AHADropDelegate

- (void)renderMixStemForPiece:(AHADropPieceData* _Nonnull)piece
				   completion:(void(^ _Nonnull)(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error))completion {
	[_innerDelegate renderMixStemForPiece:piece completion:completion];
}


- (void)renderPreviewAudioForPiece:(AHADropPieceData* _Nonnull)piece
						completion:(void(^ _Nonnull)(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error))completion {
	if ([_innerDelegate respondsToSelector:@selector(renderPreviewAudioForPiece:completion:)]) {
		[_innerDelegate renderPreviewAudioForPiece:piece completion:completion];
	}
	else {
		completion(nil, nil);
	}
}

- (void)renderCoverImageForPiece:(AHADropPieceData* _Nonnull)piece
					  completion:(void(^ _Nonnull)(UIImage* _Nullable))completion {
	if ([_innerDelegate respondsToSelector:@selector(renderCoverImageForPiece:completion:)]) {
		[_innerDelegate renderCoverImageForPiece:piece completion:completion];
	}
	else {
		completion(nil);
	}
}

- (void)dropViewController:(UIViewController *)sender forPieceWillClose:(AHADropPieceData *)piece afterSuccessfulDrop:(BOOL)successfulDrop {
	[_activity activityDidFinish:successfulDrop];

	if ([_innerDelegate respondsToSelector:@selector(dropViewController:forPieceWillClose:afterSuccessfulDrop:)]) {
		[_innerDelegate dropViewController:sender forPieceWillClose:piece afterSuccessfulDrop:successfulDrop];
	}
}

@end
