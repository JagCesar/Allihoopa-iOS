#import "DropDoneViewController.h"
#import "../Allihoopa+Internal.h"
#import "../AllihoopaInstaller/AllihoopaInstallerViewController.h"

@interface AHADropDoneViewController ()
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView *recordPatternImage;
@property (strong, nonatomic) IBOutlet UIImageView *coverImageView;
@property (strong, nonatomic) NSString *pieceIdentifier;
@end

@implementation AHADropDoneViewController {
	NSString* _pieceTitle;
	UIImage* _coverImage;
}

- (void)viewDidLoad {
	NSAssert(_pieceTitle != nil, @"Piece title must be set");
	NSAssert(_pieceIdentifier!= nil, @"Piece identifier must be set");

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
	  initWithString:NSLocalizedStringFromTableInBundle( @"You dropped your piece:\n", @"UserFacingText", AHAGetResourceBundle(), nil )
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

- (void)setPieceTitle:(NSString *)title coverImage:(UIImage *)coverImage identifier:(NSString *)identifier {
	_pieceTitle = [title copy];
	_coverImage = coverImage;
    [self setPieceIdentifier:identifier];
}

- (IBAction)viewOnAllihoopa {
    NSURL *pieceURL = [[NSURL alloc] initWithString:[NSString stringWithFormat:@"ah-allihoopa://allihoopa.com/s/%@", _pieceIdentifier]];
    if ([[UIApplication sharedApplication] openURL:pieceURL] == NO) {
        AllihoopaInstallerViewController *allihoopaInstallerViewController = [[AllihoopaInstallerViewController alloc] initWithPieceIdentifier:_pieceIdentifier nibName:@"AllihoopaInstallerView" bundle:[NSBundle bundleForClass:[AllihoopaInstallerViewController class]]];
        [allihoopaInstallerViewController setModalPresentationStyle:UIModalPresentationFormSheet];
        [self presentViewController:allihoopaInstallerViewController animated:true completion:nil];
    }
}

@end
