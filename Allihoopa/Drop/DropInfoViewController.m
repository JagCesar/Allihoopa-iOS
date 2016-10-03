#import "DropInfoViewController.h"

#import "DropProgressViewController.h"

@interface AHADropInfoViewController ()

@property (strong, nonatomic) IBOutlet UITextField *titleEditorView;
@property (strong, nonatomic) IBOutlet UIImageView *coverImageView;
@property (strong, nonatomic) IBOutlet UITextView *descriptionEditorView;
@property (strong, nonatomic) IBOutlet UISwitch *listedSwitch;
@property (strong, nonatomic) IBOutlet UIButton *dropButton;

@property (copy, nonatomic) NSString* defaultTitle;
@property (strong, nonatomic) UIImage* defaultCoverImage;

@end


@implementation AHADropInfoViewController

- (void)viewDidLoad {
	NSAssert(_dropInfoDelegate != nil, @"Internal error: Must set drop info delegate");

	_descriptionEditorView.textContainer.lineFragmentPadding = 0;
}

- (void)viewWillAppear:(__unused BOOL)animated {
	NSAssert(_titleEditorView != nil, @"Internal error: missing title editor");
	NSAssert(_coverImageView != nil, @"Internal error: missing cover image view");

	if (_defaultTitle) {
		_titleEditorView.text = _defaultTitle;
	}

	if (_defaultCoverImage) {
		_coverImageView.image = _defaultCoverImage;
	}
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(__unused id)sender {
	if ([segue.identifier isEqualToString:@"startDrop"]) {
		id<AHADropInfoViewControllerDelegate> delegate = _dropInfoDelegate;
		NSAssert(delegate != nil, @"Internal error: drop info delegate must be alive when dropping");

		[delegate dropInfoViewControllerDidCommitTitle:_titleEditorView.text
										   description:_descriptionEditorView.text
												listed:_listedSwitch.on
											coverImage:_coverImageView.image];

		AHADropProgressViewController* progressVC = segue.destinationViewController;
		NSAssert([progressVC isKindOfClass:[AHADropProgressViewController class]],
				 @"Internal error: must segue to drop progress view controller from info view");

		[delegate dropInfoViewControllerWillSegueToProgressViewController:progressVC];
	}
}

@end
