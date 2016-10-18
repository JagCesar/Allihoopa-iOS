#import "DropDoneViewController.h"

@interface AHADropDoneViewController ()
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView *recordPatternImage;
@property (strong, nonatomic) IBOutlet UIImageView *coverImageView;
@end

@implementation AHADropDoneViewController {
	NSString* _pieceTitle;
	NSURL* _playerURL;
	UIImage* _coverImage;
}

- (void)viewDidLoad {
	NSAssert(_pieceTitle != nil, @"Piece title must be set");
	NSAssert(_playerURL != nil, @"Player URL must be set");

	NSAssert(_recordPatternImage != nil, @"Record pattern image must be set");
	NSAssert(_titleLabel != nil, @"Title label must be set");

	self.navigationItem.hidesBackButton = YES;

	NSMutableAttributedString* title = [[NSMutableAttributedString alloc] init];

	UIFont* titleFont = [UIFont preferredFontForTextStyle:UIFontTextStyleTitle1];
	UIFont* boldTitleFont = [UIFont
							 fontWithDescriptor:[titleFont.fontDescriptor
												 fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold]
							 size:titleFont.pointSize];

	[title appendAttributedString:
	 [[NSAttributedString alloc]
	  initWithString:@"Yay, you dropped your piece "
	  attributes:@{ NSFontAttributeName: titleFont }]];

	[title appendAttributedString:
	 [[NSAttributedString alloc]
	  initWithString:_pieceTitle
	  attributes:@{ NSFontAttributeName: boldTitleFont }]];

	_titleLabel.attributedText = title;

	_recordPatternImage.layer.masksToBounds = YES;

	if (_coverImage) {
		_coverImageView.image = _coverImage;
	}
	else {
		_coverImageView.alpha = 0;
		_recordPatternImage.alpha = 0;
	}

	_recordPatternImage.transform = CGAffineTransformMakeRotation((CGFloat)M_PI / 2);
	_coverImageView.layer.borderColor = [UIColor colorWithRed:0.58f green:0.58f blue:0.58f alpha:1.0].CGColor;
	_coverImageView.layer.borderWidth = 1;
}

- (void)viewDidLayoutSubviews {
	_recordPatternImage.layer.cornerRadius = CGRectGetWidth(_recordPatternImage.frame) / 2;
}

- (void)setPieceTitle:(NSString *)title playerURL:(NSURL *)url coverImage:(UIImage *)coverImage {
	_pieceTitle = [title copy];
	_playerURL = [url copy];
	_coverImage = coverImage;
}

- (IBAction)viewOnAllihoopa {
	[[UIApplication sharedApplication] openURL:_playerURL];
}

@end
