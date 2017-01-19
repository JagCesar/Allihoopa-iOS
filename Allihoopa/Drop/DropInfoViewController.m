#import "DropInfoViewController.h"

#import <Accounts/Accounts.h>
#import <AllihoopaCore/AllihoopaCore.h>

#import "../Allihoopa+Internal.h"

#import "DropProgressViewController.h"
#import "ModalEditor.h"


typedef NS_ENUM(NSInteger, AHAModalEditMode) {
	AHAModalEditModeNone,
	AHAModalEditModeTitle,
	AHAModalEditModeDescription,
};


@interface AHADropInfoViewController () <UIImagePickerControllerDelegate, UINavigationControllerDelegate>

@property (strong, nonatomic) IBOutlet UILabel* titleLabel;
@property (strong, nonatomic) IBOutlet UIImageView* coverImageView;
@property (strong, nonatomic) IBOutlet UILabel* descriptionLabel;
@property (strong, nonatomic) IBOutlet UISwitch* listedSwitch;
@property (strong, nonatomic) IBOutlet UILabel* listedCaption;
@property (strong, nonatomic) IBOutlet UILabel* addDescriptionLabel;
@property (strong, nonatomic) IBOutlet UIImageView* addDescriptionButton;
@property (strong, nonatomic) IBOutlet UIButton* dropButton;

@property (strong, nonatomic) IBOutlet UIButton* facebookPostingButton;
@property (strong, nonatomic) IBOutlet UIButton* twitterPostingButton;

@property (copy, nonatomic) NSString* defaultTitle;
@property (strong, nonatomic) UIImage* defaultCoverImage;
@property (nonatomic) BOOL coverImageOverridden;

@end


@implementation AHADropInfoViewController {
	AHAModalEditMode _modalEditMode;

	ACAccount* _facebookAccount;
	ACAccountCredential* _facebookAccountCredential;
	ACAccount* _twitterAccount;

	UIImagePickerController* _imagePicker;
}

- (void)viewDidLoad {
	NSAssert(_dropInfoDelegate != nil, @"Must set drop info delegate");
	NSAssert(_configuration != nil, @"Must set configuration object");

	NSAssert(_titleLabel != nil, @"Missing title label");
	NSAssert(_coverImageView != nil, @"Missing cover image view");
	NSAssert(_descriptionLabel != nil, @"Missing description label");
	NSAssert(_listedSwitch != nil, @"Missing listed switch");

	[self validateCameraPermissions];

	if (_defaultTitle) {
		_titleLabel.text = _defaultTitle;
	}

	if (_defaultCoverImage) {
		_coverImageView.image = _defaultCoverImage;
	}

	_descriptionLabel.text = @"";
	_dropButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
	_dropButton.titleEdgeInsets = UIEdgeInsetsMake(0, -50, 0, 0);

	if (_configuration.facebookAppID == nil) {
		_facebookPostingButton.hidden = YES;
	}

	[self onListedChange:_listedSwitch];
}

- (void)viewDidLayoutSubviews {
	CGFloat buttonHeight = CGRectGetHeight(_dropButton.frame);
	CGFloat imageHeight = 22;
	_dropButton.imageEdgeInsets = UIEdgeInsetsMake((buttonHeight - imageHeight) / 2, 0,
												   (buttonHeight - imageHeight) / 2, 0);
}

- (void)segueToProgressViewController {
	[self performSegueWithIdentifier:@"startDrop" sender:nil];
}

- (IBAction)commitEditor {
	id<AHADropInfoViewControllerDelegate> delegate = _dropInfoDelegate;
	NSAssert(delegate != nil, @"Drop info delegate must be alive when dropping");

	UIImage* coverImage = _coverImageOverridden ? _coverImageView.image : nil;

	AHADropInfo* info = [[AHADropInfo alloc] initWithTitle:_titleLabel.text
										  pieceDescription:_descriptionLabel.text
													listed:_listedSwitch.on
												coverImage:coverImage
										   facebookAccount:_facebookAccount
								 facebookAccountCredential:_facebookAccountCredential
											twitterAccount:_twitterAccount];

	[delegate dropInfoViewControllerDidCommit:info];
}

- (IBAction)unwindFromModalEditor:(UIStoryboardSegue*)segue {
	AHAModalEditor* editor = segue.sourceViewController;
	NSAssert([editor isKindOfClass:[AHAModalEditor class]],
			 @"endModalEditor unwind must originate from ModalEditor");
	NSAssert(_modalEditMode != AHAModalEditModeNone,
			 @"Must be in modal editing mode when unwinding");

	if (_modalEditMode == AHAModalEditModeTitle) {
		// Replace newlines with spaces in title
		_titleLabel.text = [[editor.text
							 componentsSeparatedByCharactersInSet:[NSCharacterSet newlineCharacterSet]]
							componentsJoinedByString:@" "];

	}
	else if (_modalEditMode == AHAModalEditModeDescription) {
		_descriptionLabel.text = editor.text;

		BOOL showPlaceholder = [_descriptionLabel.text
								stringByTrimmingCharactersInSet:[NSCharacterSet
																 whitespaceAndNewlineCharacterSet]].length == 0;

		_addDescriptionLabel.alpha = showPlaceholder ? 1 : 0;
		_addDescriptionButton.alpha = showPlaceholder ? 1 : 0;
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
		[editor setTitle:NSLocalizedStringFromTableInBundle( @"Title of your piece", @"UserFacingText", AHAGetResourceBundle(), nil )
			   maxLength:50
					text:_titleLabel.text
				   style:_titleLabel.font];
	}
	else if ([segue.identifier isEqualToString:@"editDescription"]) {
		NSAssert(_modalEditMode == AHAModalEditModeNone,
				 @"Can't be in a modal editing mode when entering description editor");

		AHAModalEditor* editor = segue.destinationViewController;
		NSAssert([editor isKindOfClass:[AHAModalEditor class]],
				 @"Must segue to modal editor for editDescription");

		_modalEditMode = AHAModalEditModeDescription;
		[editor setTitle:NSLocalizedStringFromTableInBundle( @"Description and tags", @"UserFacingText", AHAGetResourceBundle(), nil )
			   maxLength:140
					text:_descriptionLabel.text
				   style:_descriptionLabel.font];
	}
	else {
		AHALog(@"Prepare for segue: %@", segue);
	}
}

- (IBAction)onListedChange:(UISwitch *)sender {
	[UIView transitionWithView:_listedCaption duration:0.25 options:UIViewAnimationOptionTransitionCrossDissolve animations:^{
		
		if (sender.on) {
			self->_listedCaption.text = NSLocalizedStringFromTableInBundle( @"Anyone can see this", @"UserFacingText", AHAGetResourceBundle(), nil );
		}
		else {
			self->_listedCaption.text = NSLocalizedStringFromTableInBundle( @"Only people with a link can see this", @"UserFacingText", AHAGetResourceBundle(), nil );
		}
	} completion:nil];

}

- (IBAction)editCoverImage:(UIView*)sender {
	NSAssert(_imagePicker == nil, @"Can't have two active image pickers");

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:nil
																   message:nil
															preferredStyle:UIAlertControllerStyleActionSheet];

	[alert addAction:[UIAlertAction actionWithTitle:@"Photo Library" style:0 handler:^(__unused UIAlertAction * _Nonnull action) {
		[self openPhotoLibraryPicker:sender];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Take Photo or Video" style:0 handler:^(__unused UIAlertAction * _Nonnull action) {
		[self openCameraPicker];
	}]];
	[alert addAction:[UIAlertAction actionWithTitle:@"Cancel" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction * _Nonnull action) {
	}]];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)validateCameraPermissions {
	NSBundle* bundle = [NSBundle mainBundle];

	if (![bundle objectForInfoDictionaryKey:@"NSCameraUsageDescription"]) {
		AHARaiseInvalidUsageException(@"The application's Info.plist file must contain an entry for NSCameraUsageDescription");
	}

	if (![bundle objectForInfoDictionaryKey:@"NSPhotoLibraryUsageDescription"]) {
		AHARaiseInvalidUsageException(@"The application's Info.plist file must contain an entry for NSPhotoLibraryUsageDescription");
	}
}

#pragma mark - Private methods (social service posting)

- (IBAction)toggleFacebookPosting:(__unused id)sender {
	BOOL enabled = !_facebookPostingButton.selected;
	_facebookPostingButton.selected = enabled;

	[UIView animateWithDuration:0.25 animations:^{
		[self->_facebookPostingButton layoutIfNeeded];
	}];

	if (enabled) {
		ACAccountStore* store = [[ACAccountStore alloc] init];
		ACAccountType* type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierFacebook];
		NSDictionary* options = @{ ACFacebookAppIdKey: _configuration.facebookAppID,
								   ACFacebookPermissionsKey: @[@"publish_actions"],
								   ACFacebookAudienceKey: ACFacebookAudienceEveryone };

		__weak AHADropInfoViewController* weakSelf = self;
		[store requestAccessToAccountsWithType:type options:options completion:^(BOOL granted, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				AHADropInfoViewController* strongSelf = weakSelf;

				AHALog(@"Got access to Facebook account: %i, %@", granted, error);

				if (strongSelf) {
					strongSelf->_facebookPostingButton.selected = granted;
					strongSelf->_facebookAccount = granted ? [store accountsWithAccountType:type].firstObject : nil;
					strongSelf->_facebookAccountCredential = strongSelf->_facebookAccount.credential;

					if (!granted && error == nil) {
						[strongSelf showSocialServiceDisabled:@"Facebook"];
					}
					else if ([error.domain isEqualToString:ACErrorDomain] && error.code == ACErrorAccountNotFound) {
						[strongSelf showSocialServiceNotFound:@"Facebook"];
					}
				}
			});
		}];
	}
	else {
		_facebookAccount = nil;
	}
}

- (IBAction)toggleTwitterPosting:(__unused id)sender {
	BOOL enabled = !_twitterPostingButton.selected;
	_twitterPostingButton.selected = enabled;

	[UIView animateWithDuration:0.25 animations:^{
		[self->_twitterPostingButton layoutIfNeeded];
	}];

	if (enabled) {
		ACAccountStore* store = [[ACAccountStore alloc] init];
		ACAccountType* type = [store accountTypeWithAccountTypeIdentifier:ACAccountTypeIdentifierTwitter];

		__weak AHADropInfoViewController* weakSelf = self;
		[store requestAccessToAccountsWithType:type options:nil completion:^(BOOL granted, NSError *error) {
			dispatch_async(dispatch_get_main_queue(), ^{
				AHADropInfoViewController* strongSelf = weakSelf;

				AHALog(@"Got access to Twitter account: %i, %@", granted, error);

				if (strongSelf) {
					strongSelf->_twitterPostingButton.selected = granted;
					strongSelf->_twitterAccount = granted ? [store accountsWithAccountType:type].firstObject : nil;

					if (!granted && error == nil) {
						[strongSelf showSocialServiceDisabled:@"Twitter"];
					}
					else if ([error.domain isEqualToString:ACErrorDomain] && error.code == ACErrorAccountNotFound) {
						[strongSelf showSocialServiceNotFound:@"Twitter"];
					}
				}
			});
		}];
	}
	else {
		_twitterAccount = nil;
	}
}

- (void)showSocialServiceDisabled:(NSString*)serviceName {
	NSString* appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"];

	if (appName == nil) {
		appName = @"this app"; // :)
	}

	NSString* message = [NSString stringWithFormat:@"Sharing to %@ has been disabled. Please enable %@ to post to %@ in the Settings app",
						 serviceName,
						 appName,
						 serviceName];

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Sharing Disabled"
																   message:message
															preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction * _Nonnull action) {}]];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)showSocialServiceNotFound:(NSString*)serviceName {
	NSString* message = [NSString stringWithFormat:@"No %@ account has been set up. Please go to the Settings app and log in to %@.",
						 serviceName,
						 serviceName];

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"No Account Found"
																   message:message
															preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction * _Nonnull action) {}]];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)openPhotoLibraryPicker:(UIView*)sender {
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypePhotoLibrary]) {
		AHALog(@"Photo library not available");
		return;
	}

	UIImagePickerController* picker = [[UIImagePickerController alloc] init];
	picker.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;
	picker.delegate = self;
	picker.allowsEditing = YES;
	picker.modalPresentationStyle = UIModalPresentationPopover;

	UIPopoverPresentationController* presentationController = picker.popoverPresentationController;
	presentationController.sourceView = sender;
	presentationController.sourceRect = sender.bounds;
	presentationController.permittedArrowDirections = UIPopoverArrowDirectionAny;

	_imagePicker = picker;

	[self presentViewController:picker animated:YES completion:nil];
}

- (void)openCameraPicker {
	if (![UIImagePickerController isSourceTypeAvailable:UIImagePickerControllerSourceTypeCamera]) {
		AHALog(@"Camera not available");
		return;
	}

	UIImagePickerController* picker = [[UIImagePickerController alloc] init];
	picker.sourceType = UIImagePickerControllerSourceTypeCamera;
	picker.delegate = self;
	picker.allowsEditing = YES;
	picker.modalPresentationStyle = UIModalPresentationFullScreen;

	_imagePicker = picker;

	[self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIImagePickerControllerDelegate

- (void)imagePickerControllerDidCancel:(__unused UIImagePickerController *)picker {
	AHALog(@"Cancel picker");

	_imagePicker = nil;
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)imagePickerController:(__unused UIImagePickerController *)picker
didFinishPickingMediaWithInfo:(NSDictionary<NSString *,id> *)info {
	AHALog(@"Commit picker");

	UIImage* image = info[UIImagePickerControllerEditedImage];
	NSAssert(image != nil, @"Image must exist");

	CGRect cropSource;

	if (image.size.width > image.size.height) {
		cropSource = CGRectMake((image.size.width - image.size.height) / 2, 0,
								image.size.height, image.size.height);
	}
	else {
		cropSource = CGRectMake(0, (image.size.height - image.size.width) / 2,
								image.size.width, image.size.width);
	}

	const CGFloat destSize = 640;

	CGImageRef croppedRaw = CGImageCreateWithImageInRect(image.CGImage, cropSource);
	UIImage* cropped = [UIImage imageWithCGImage:croppedRaw scale:1 orientation:image.imageOrientation];
	CGImageRelease(croppedRaw);

	UIGraphicsBeginImageContext(CGSizeMake(destSize, destSize));

	[cropped drawInRect:CGRectMake(0, 0, destSize, destSize)];

	_coverImageView.image = UIGraphicsGetImageFromCurrentImageContext();
	_coverImageOverridden = YES;
	UIGraphicsEndImageContext();

	_imagePicker = nil;
	[self dismissViewControllerAnimated:YES completion:nil];
}

@end
