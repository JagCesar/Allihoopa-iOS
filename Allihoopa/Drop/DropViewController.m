#import "DropViewController.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>
#import <AllihoopaCore/AllihoopaCore.h>

#import "../AllihoopaSDK.h"
#import "../Allihoopa+Internal.h"
#import "../DropDelegate.h"

#import "DropInfoViewController.h"
#import "DropProgressViewController.h"
#import "DropDoneViewController.h"

@interface AHADropViewController ()
<AHADropInfoViewControllerDelegate, AHADropProgressViewControllerDelegate, AHADropCoordinatorDelegate>

@end

@implementation AHADropViewController {
	AHADropInfoViewController* _infoViewController;
	AHADropProgressViewController* _progressViewController;
	AHADropDoneViewController* _doneViewController;

	BOOL _hasBeenPresented;

	AHADropCoordinator* _dropCoordinator;

	NSDictionary* _createdPiece;
	UIImage* _downloadedCoverImage;
}



#pragma mark - View controller lifecycle

- (void)viewDidLoad {
	NSAssert(_dropPieceData != nil, @"Initial drop piece data must be set for the drop view controller");

	NSAssert(_configuration != nil, @"Configuration not set for drop view controller");
	NSAssert(self.viewControllers.count, @"A root view controller must be set");
	NSAssert([self.viewControllers[0] isKindOfClass:[AHADropInfoViewController class]],
			 @"Root view controller must be drop info");

	_infoViewController = self.viewControllers[0];
	_infoViewController.dropInfoDelegate = self;
	_infoViewController.configuration = _configuration;

	[_infoViewController setDefaultTitle:_dropPieceData.defaultTitle];

	_dropCoordinator = [[AHADropCoordinator alloc] initWithConfiguration:_configuration
													 coordinatorDelegate:self
															dropDelegate:_dropDelegate
															   pieceData:_dropPieceData];
}

- (void)viewDidAppear:(__unused BOOL)animated {
	if (!_hasBeenPresented) {
		_hasBeenPresented = YES;

		__weak AHADropViewController* weakSelf = self;
		[[AHAAllihoopaSDK sharedInstance] authenticate:^(BOOL successful) {
			AHADropViewController* strongSelf = weakSelf;

			if (strongSelf) {
				if (successful) {
					[strongSelf->_dropCoordinator runDropFlow];
				}
				else {
					[strongSelf cancelDropUnwind:nil];
				}
			}
		}];
	}
}

- (void)dealloc {
	AHALog(@"Deallocing AHADropViewController");
}

- (UIInterfaceOrientationMask)supportedInterfaceOrientations {
	if ([UIDevice currentDevice].userInterfaceIdiom == UIUserInterfaceIdiomPad) {
		return UIInterfaceOrientationMaskAll;
	}

	return UIInterfaceOrientationMaskPortrait;
}


#pragma mark - IBActions / Unwind segue actions

- (IBAction)cancelDropUnwind:(__unused UIStoryboardSegue*)segue {
	BOOL dropSuccessful = NO;
	if ([segue.sourceViewController isKindOfClass:[AHADropDoneViewController class]]) {
		dropSuccessful = YES;
	}

	id<AHADropDelegate> delegate = _dropDelegate;
	if ([delegate respondsToSelector:@selector(dropViewController:forPieceWillClose:afterSuccessfulDrop:)]) {
		[delegate dropViewController:self forPieceWillClose:_dropPieceData afterSuccessfulDrop:dropSuccessful];
	}

	if (_dismissWhenCloseTapped) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}

#pragma mark - AHADropInfoViewControllerDelegate

- (void)dropInfoViewControllerDidCommit:(AHADropInfo*)dropInfo
{
	AHALog(@"Info view committed piece information");

	NSAssert(dropInfo.title != nil, @"Must commit title");
	NSAssert(dropInfo.pieceDescription != nil, @"Must commit description");

	[_dropCoordinator commitPieceInfo:dropInfo];
}

- (void)dropInfoViewControllerWillSegueToProgressViewController:(AHADropProgressViewController*)dropProgressViewController {
	NSAssert(dropProgressViewController != nil, @"No drop progress view controller provided");
	NSAssert(_progressViewController == nil, @"Transition to progress view controller multiple times");

	_progressViewController = dropProgressViewController;
	_progressViewController.dropProgressDelegate = self;
}

#pragma mark - AHADropProgressViewControllerDelegate

- (void)dropProgressViewControllerWillSegueToDoneViewController:(AHADropDoneViewController *)dropDoneViewController {
	NSAssert(dropDoneViewController != nil, @"No drop done view controller provided");
	NSAssert(_doneViewController == nil, @"Transition to done view controller multiple times");
	NSAssert(_createdPiece != nil, @"Piece must be created when transitioning to drop done");

	_doneViewController = dropDoneViewController;

	NSString* title = _createdPiece[@"title"];
	NSString* url = _createdPiece[@"url"];

	NSAssert(title != nil && [title isKindOfClass:[NSString class]], @"Title expected in GraphQL response");
	NSAssert(url != nil && [url isKindOfClass:[NSString class]], @"URL expected in GraphQL response");

	[_doneViewController setPieceTitle:title
							 playerURL:[NSURL URLWithString:url]
							coverImage:_downloadedCoverImage];
}

#pragma mark - AHADropCoordinatorDelegate

- (void)defaultCoverImageDidArrive:(UIImage *)image {
	[_infoViewController setDefaultCoverImage:image];
}

- (void)socialQuickPostingFailedForNetwork:(NSString *)networkName {
	NSString* message = [NSString stringWithFormat:@"Could not share this piece to %@ :(", networkName];

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Sharing Error"
																   message:message
															preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction * _Nonnull action) {}]];

	[self presentViewController:alert animated:YES completion:nil];
}

- (void)didCreatePiece:(NSDictionary *)createdPiece {
	_createdPiece = createdPiece;
}

- (void)didDownloadFinalCoverImage:(UIImage *)image {
	_downloadedCoverImage = image;
}

- (void)segueToProgressViewController {
	NSAssert(_infoViewController != nil, @"Info view controller must be present");

	[_infoViewController segueToProgressViewController];
}

- (void)segueToErrorViewController {
	[self performSegueWithIdentifier:@"dropError" sender:nil];
}

- (void)segueToDropDoneViewController {
	NSAssert(_progressViewController != nil, @"Progress view controller must be present");

	[_progressViewController advanceToDropDone];
}

@end
