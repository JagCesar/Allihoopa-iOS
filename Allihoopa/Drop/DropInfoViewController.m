#import "DropInfoViewController.h"

#import "../Allihoopa+Internal.h"

#import "DropProgressViewController.h"
#import "ModalEditor.h"


typedef NS_ENUM(NSInteger, AHAModalEditMode) {
	AHAModalEditModeNone,
	AHAModalEditModeTitle,
	AHAModalEditModeDescription,
};


@interface AHADropInfoViewController ()

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView* coverImageView;
@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UISwitch* listedSwitch;

@property (copy, nonatomic) NSString* defaultTitle;
@property (strong, nonatomic) UIImage* defaultCoverImage;
@property (nonatomic) BOOL coverImageOverridden;

@end


@implementation AHADropInfoViewController {
	AHAModalEditMode _modalEditMode;
}

- (void)viewDidLoad {
	NSAssert(_dropInfoDelegate != nil, @"Must set drop info delegate");

	NSAssert(_titleLabel != nil, @"Missing title label");
	NSAssert(_coverImageView != nil, @"Missing cover image view");
	NSAssert(_descriptionLabel != nil, @"Missing description label");
	NSAssert(_listedSwitch != nil, @"Missing listed switch");

	if (_defaultTitle) {
		_titleLabel.text = _defaultTitle;
	}

	if (_defaultCoverImage) {
		_coverImageView.image = _defaultCoverImage;
	}
}

- (void)segueToProgressViewController {
	[self performSegueWithIdentifier:@"startDrop" sender:nil];
}

- (IBAction)commitEditor {
	id<AHADropInfoViewControllerDelegate> delegate = _dropInfoDelegate;
	NSAssert(delegate != nil, @"Drop info delegate must be alive when dropping");

	UIImage* coverImage = _coverImageOverridden ? _coverImageView.image : nil;

	[delegate dropInfoViewControllerDidCommitTitle:_titleLabel.text
									   description:_descriptionLabel.text
											listed:_listedSwitch.on
										coverImage:coverImage];
}

- (IBAction)unwindFromModalEditor:(UIStoryboardSegue*)segue {
	AHAModalEditor* editor = segue.sourceViewController;
	NSAssert([editor isKindOfClass:[AHAModalEditor class]],
			 @"endModalEditor unwind must originate from ModalEditor");
	NSAssert(_modalEditMode != AHAModalEditModeNone,
			 @"Must be in modal editing mode when unwinding");

	if (_modalEditMode == AHAModalEditModeTitle) {
		_titleLabel.text = editor.text;
	}
	else if (_modalEditMode == AHAModalEditModeDescription) {
		_descriptionLabel.text = editor.text;
	}

	[self.view setNeedsLayout];

	_modalEditMode = AHAModalEditModeNone;
}

- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(__unused id)sender {
	if ([segue.identifier isEqualToString:@"startDrop"]) {
		id<AHADropInfoViewControllerDelegate> delegate = _dropInfoDelegate;
		NSAssert(delegate != nil, @"Drop info delegate must be alive when dropping");

		AHADropProgressViewController* progressVC = segue.destinationViewController;
		NSAssert([progressVC isKindOfClass:[AHADropProgressViewController class]],
				 @"Must segue to drop progress view controller from info view");

		[delegate dropInfoViewControllerWillSegueToProgressViewController:progressVC];
	}
	else if ([segue.identifier isEqualToString:@"editTitle"]) {
		NSAssert(_modalEditMode == AHAModalEditModeNone,
				 @"Can't be in a modal editing mode when entering title editor");

		AHAModalEditor* editor = segue.destinationViewController;
		NSAssert([editor isKindOfClass:[AHAModalEditor class]],
				 @"Must segue to modal editor for editTitle");

		_modalEditMode = AHAModalEditModeTitle;
		[editor setTitle:@"Title of your piece" maxLength:50 text:_titleLabel.text];
	}
	else if ([segue.identifier isEqualToString:@"editDescription"]) {
		NSAssert(_modalEditMode == AHAModalEditModeNone,
				 @"Can't be in a modal editing mode when entering description editor");

		AHAModalEditor* editor = segue.destinationViewController;
		NSAssert([editor isKindOfClass:[AHAModalEditor class]],
				 @"Must segue to modal editor for editDescription");

		_modalEditMode = AHAModalEditModeDescription;
		[editor setTitle:@"Description and tags" maxLength:140 text:_descriptionLabel.text];
	}
	else {
		AHALog(@"Prepare for segue: %@", segue);
	}
}

@end
