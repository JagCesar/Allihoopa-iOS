#import "DropViewController.h"

#import "../Allihoopa+Internal.h"

#import "../DropDelegate.h"
#import "../Configuration.h"
#import "../APICommunication.h"
#import "../Errors.h"

#import "DropInfoViewController.h"
#import "DropProgressViewController.h"
#import "AssetUpload.h"

static NSString* const kCreatePieceQuery = @"\
mutation($piece: PieceInput!) {\
  dropPiece(piece: $piece) {\
    piece {\
      uuid\
      shortId\
    }\
  }\
}\
";

typedef NS_ENUM(NSInteger, AHADropViewState) {
	AHADropViewStateEditInfo,
	AHADropViewStateProgress,
	AHADropViewStateDone,
	AHADropViewStateError,
};

@interface AHADropViewController () <AHADropInfoViewControllerDelegate>
@end

@implementation AHADropViewController {
	AHADropInfoViewController* _infoViewController;
	AHADropProgressViewController* _progressViewController;

	AHADropViewState _viewState;

	BOOL _waitingForPieceInfo;
	NSString* _committedTitle;
	NSString* _committedDescription;
	BOOL _committedListed;
	UIImage* _committedCoverImage;

	BOOL _waitingForCoverImage;
	NSURL* _coverImageURL;

	BOOL _waitingForMixStem;
	AHAAudioDataBundle* _mixStemBundle;
	NSURL* _mixStemURL;

	BOOL _waitingForPreviewAudio;
	AHAAudioDataBundle* _previewAudioBundle;
	NSURL* _previewAudioURL;

	BOOL _waitingForCreatePiece;
	NSDictionary* _createdPiece;

	NSError* _currentError;
}



#pragma mark - View controller lifecycle

- (void)viewDidLoad {
	NSAssert(_dropDelegate != nil, @"A delegate must be set for the drop view controller");
	NSAssert(_dropPieceData != nil, @"Initial drop piece data must be set for the drop view controller");

	NSAssert(_configuration != nil, @"Configuration not set for drop view controller");
	NSAssert(self.viewControllers.count, @"A root view controller must be set");
	NSAssert([self.viewControllers[0] isKindOfClass:[AHADropInfoViewController class]],
			 @"Root view controller must be drop info");

	_infoViewController = self.viewControllers[0];
	_infoViewController.dropInfoDelegate = self;

	_viewState = AHADropViewStateEditInfo;

	_waitingForPieceInfo = YES;

	[_infoViewController setDefaultTitle:_dropPieceData.defaultTitle];
	[self fetchDefaultCoverImage];
	[self fetchMixStem];
	[self fetchPreviewAudio];
}



#pragma mark - IBActions / Unwind segue actions

- (IBAction)cancelDropUnwind:(__unused UIStoryboardSegue*)segue {
	if ([self.dropDelegate respondsToSelector:@selector(dropViewControllerForPieceWillClose:)]) {
		[self.dropDelegate dropViewControllerForPieceWillClose:_dropPieceData];
	}

	if (_dismissWhenCloseTapped) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}



#pragma mark - Private methods (delegate data fetching)

- (void)fetchDefaultCoverImage {
	if ([_dropDelegate respondsToSelector:@selector(renderCoverImageForPiece:completion:)]) {
		AHALog(@"Fetching default cover image from application");

		__weak AHADropViewController* weakSelf = self;
		[_dropDelegate renderCoverImageForPiece:_dropPieceData completion:^(UIImage* _Nullable image) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf coverImageDidArrive:image];
		}];
	}
}

- (void)coverImageDidArrive:(UIImage*)image {
	if (![NSThread isMainThread]) {
		AHARaiseInvalidUsageException(@"Must call completion handlers on main queue");
	}

	AHALog(@"Default cover image arrived from application");
	NSAssert(_infoViewController != nil, @"Info view must be set");

	[_infoViewController setDefaultCoverImage:image];
}

- (void)coverImageDidCompleteUpload:(NSURL*)url error:(NSError*)error {
	AHALog(@"Cover image upload completed, error: %@", error);

	_coverImageURL = url;
	_waitingForCoverImage = NO;
	if (!_currentError) {
		_currentError = error;
	}

	[self tick];
}

- (void)fetchMixStem {
	AHALog(@"Fetching mix stem from application");

	_waitingForMixStem = YES;
	__weak AHADropViewController* weakSelf = self;

	[_dropDelegate renderMixStemForPiece:_dropPieceData completion:^(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error) {
		AHADropViewController* strongSelf = weakSelf;

		[strongSelf mixStemDidArrive:bundle error:error];
	}];
}

- (void)mixStemDidArrive:(AHAAudioDataBundle*)bundle error:(NSError*)fetchError {
	if (![NSThread isMainThread]) {
		AHARaiseInvalidUsageException(@"Must call completion handlers on main queue");
	}

	AHALog(@"Mix stem arrived from application, error: %@", bundle);

	if (bundle) {
		AHALog(@"Uploading mix stem");
		__weak AHADropViewController* weakSelf = self;
		AHAUploadAssetData(_configuration, bundle.data, ^(NSURL *url, NSError *uploadError) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf mixStemDidCompleteUpload:bundle url:url error:uploadError];
		});
	}
	else if (fetchError) {
		_waitingForMixStem = NO;
		if (!_currentError) {
			_currentError = fetchError;
		}

		[self tick];
	}
	else {
		AHARaiseInvalidUsageException(@"Either a mix stem asset bundle or error must be provided");
	}
}

- (void)mixStemDidCompleteUpload:(AHAAudioDataBundle*)bundle url:(NSURL*)url error:(NSError*)error {
	AHALog(@"Mix stem upload completed, error: %@", error);

	_mixStemBundle = bundle;
	_mixStemURL = url;
	_waitingForMixStem = NO;

	if (!_currentError) {
		_currentError = error;
	}

	[self tick];
}

- (void)fetchPreviewAudio {
	if ([_dropDelegate respondsToSelector:@selector(renderPreviewAudioForPiece:completion:)]) {
		AHALog(@"Fetching preview audio from application");
		_waitingForPreviewAudio = YES;
		__weak AHADropViewController* weakSelf;

		[_dropDelegate renderPreviewAudioForPiece:_dropPieceData completion:^(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf previewAudioDidArrive:bundle error:error];
		}];
	}
}

- (void)previewAudioDidArrive:(AHAAudioDataBundle*)bundle error:(NSError*)fetchError {
	if (![NSThread isMainThread]) {
		AHARaiseInvalidUsageException(@"Must call completion handlers on main queue");
	}

	AHALog(@"Preview audio arrived from application, error: %@", fetchError);

	if (bundle) {
		AHALog(@"Uploading preview audio");

		__weak AHADropViewController* weakSelf = self;
		AHAUploadAssetData(_configuration, bundle.data, ^(NSURL *url, NSError *uploadError) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf previewAudioDidCompleteUpload:bundle url:url error:uploadError];
		});
	}
	else {
		_waitingForPreviewAudio = NO;

		if (!_currentError) {
			_currentError = fetchError;
		}

		[self tick];
	}
}

- (void)previewAudioDidCompleteUpload:(AHAAudioDataBundle*)bundle url:(NSURL*)url error:(NSError*)error {
	AHALog(@"Preview audio upload completed, error: %@", error);
	_previewAudioBundle = bundle;
	_previewAudioURL = url;
	_waitingForPreviewAudio = NO;

	if (!_currentError) {
		_currentError = error;
	}

	[self tick];
}


#pragma mark - Private methods (piece creation)

- (void)createPieceFromParts {
	NSMutableDictionary* presentationData = [NSMutableDictionary new];
	presentationData[@"title"] = _committedTitle;
	presentationData[@"description"] = _committedDescription;
	presentationData[@"isListed"] = @(_committedListed);

	if (_previewAudioURL) {
		presentationData[@"preview"] = @{ _previewAudioBundle.formatAsString: _previewAudioURL.absoluteString };
	}

	if (_coverImageURL) {
		presentationData[@"coverImage"] = @{ @"png": _coverImageURL.absoluteString };
	}

	NSDictionary* stems = @{ @"mixStem": @{ _mixStemBundle.formatAsString: _mixStemURL.absoluteString } };

	NSMutableArray* basedOnPieces = [NSMutableArray new];
	for (AHAPieceID* pieceID in _dropPieceData.basedOnPieceIDs) {
		[basedOnPieces addObject:pieceID.pieceID];
	}

	NSDictionary* attribution = @{ @"basedOnPieces": basedOnPieces };

	NSMutableDictionary* musicalMetadata = [NSMutableDictionary new];
	musicalMetadata[@"lengthUs"] = @(_dropPieceData.lengthMicroseconds);

	if (_dropPieceData.tempo) {
		musicalMetadata[@"tempo"] = @{ @"fixed": @(_dropPieceData.tempo.fixedTempo) };
	}

	if (_dropPieceData.timeSignature) {
		musicalMetadata[@"timeSignature"] = @{ @"fixed": @{ @"upper": @(_dropPieceData.timeSignature.upper),
															@"lower": @(_dropPieceData.timeSignature.lower) } };
	}

	if (_dropPieceData.loopMarkers) {
		musicalMetadata[@"loop"] = @{ @"startUs": @(_dropPieceData.loopMarkers.startMicroseconds),
									  @"endUs": @(_dropPieceData.loopMarkers.endMicroseconds) };
	}

	NSDictionary* piece = @{ @"presentation": presentationData,
							 @"stems": stems,
							 @"attribution": attribution,
							 @"musicalMetadata": musicalMetadata,
							 };

	AHALog(@"Sending createPiece GraphQL mutation");

	__weak AHADropViewController* weakSelf = self;
	AHAGraphQLQuery(_configuration, kCreatePieceQuery, @{ @"piece": piece }, ^(NSDictionary *response, NSError *error) {
		AHADropViewController* strongSelf = weakSelf;

		[strongSelf createPieceFromPartsDidComplete:response error:error];
	});
}

- (void)createPieceFromPartsDidComplete:(NSDictionary*)piece error:(NSError*)error {
	AHALog(@"createPiece GraphQL mutation completed, error: %@", error);
	_createdPiece = piece;
	_waitingForCreatePiece = NO;

	if (!_currentError) {
		_currentError = error;
	}

	[self tick];
}

#pragma mark - Private methods (state machine)

- (void)tick {
	int waitingParts = ((_waitingForMixStem ? 1 : 0)
						+ (_waitingForPieceInfo ? 1 : 0)
						+ (_waitingForCoverImage ? 1 : 0)
						+ (_waitingForPreviewAudio ? 1 : 0));

	BOOL pieceCreated = !!_createdPiece;

	// If we've received an error and either is showing the progress view or just committed the
	// edit info screen, segue to the error screen.
	if (_currentError && (_viewState == AHADropViewStateProgress
						  || (_viewState == AHADropViewStateEditInfo && !_waitingForPieceInfo))) {
		AHALog(@"Tick: Segue to error view");

		[self performSegueWithIdentifier:@"dropError" sender:nil];
		_viewState = AHADropViewStateError;
	}
	// If we've just committed the edit info screen and no error has arrived, segue to the
	// progress view.
	else if (!_currentError && _viewState == AHADropViewStateEditInfo && !_waitingForPieceInfo) {
		AHALog(@"Tick: Segue to progress view");

		[_infoViewController segueToProgressViewController];
		_viewState = AHADropViewStateProgress;
	}
	// If all uploads are completed and the edit info is committed, send the createPiece mutation
	// to actually drop the piece.
	else if (!_currentError && waitingParts == 0 && !_waitingForCreatePiece && !pieceCreated) {
		AHALog(@"Tick: Creating piece on server");

		[self createPieceFromParts];
	}
	// If the piece is created, segue to the done screen.
	else if (pieceCreated && _viewState != AHADropViewStateDone) {
		AHALog(@"Everything is done: %@", _createdPiece);
		NSAssert(_progressViewController != nil,@"No progress view controller available");

		[_progressViewController advanceToDropDone];
		_viewState = AHADropViewStateDone;
	}
}

#pragma mark - AHADropInfoViewControllerDelegate

- (void)dropInfoViewControllerDidCommitTitle:(NSString*)title
								 description:(NSString*)description
									  listed:(BOOL)isListed
								  coverImage:(UIImage*)coverImage {
	AHALog(@"Info view committed piece information");

	NSAssert(title != nil, @"Must commit title");
	NSAssert(description != nil, @"Must commit description");
	NSAssert(_waitingForPieceInfo, @"Can't commit piece info twice");

	_committedTitle = title;
	_committedDescription = description;
	_committedListed = isListed;
	_committedCoverImage = coverImage;
	_waitingForPieceInfo = NO;

	if (_committedCoverImage != nil) {
		AHALog(@"Uploading cover image");
		_waitingForCoverImage = YES;

		__weak AHADropViewController* weakSelf = self;
		AHAUploadAssetData(_configuration, UIImagePNGRepresentation(_committedCoverImage), ^(NSURL *url, NSError *error) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf coverImageDidCompleteUpload:url error:error];
		});
	}

	[self tick];
}

- (void)dropInfoViewControllerWillSegueToProgressViewController:(AHADropProgressViewController*)dropProgressViewController {
	NSAssert(dropProgressViewController != nil, @"No drop progress view controller provided");
	NSAssert(_progressViewController == nil, @"Transition to progress view controller multiple times");

	_progressViewController = dropProgressViewController;
	_viewState = AHADropViewStateProgress;

	[self tick];
}

@end