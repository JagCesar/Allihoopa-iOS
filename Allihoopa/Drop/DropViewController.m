#import "DropViewController.h"

#import "../DropDelegate.h"
#import "../Configuration.h"
#import "../APICommunication.h"

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

@interface AHADropViewController () <AHADropInfoViewControllerDelegate>
@end

@implementation AHADropViewController {
	AHADropInfoViewController* _infoViewController;
	AHADropProgressViewController* _progressViewController;

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
}



#pragma mark - View controller lifecycle

- (void)viewDidLoad {
	NSAssert(_dropDelegate != nil,
			 @"A delegate must be set for the drop view controller");
	NSAssert(_dropPieceData != nil,
			 @"Initial drop piece data must be set for the drop view controller");

	NSAssert(_configuration != nil,
			 @"Internal error: configuration not set for drop view controller");
	NSAssert(self.viewControllers.count,
			 @"Internal error: a root view controller must be set");
	NSAssert([self.viewControllers[0] isKindOfClass:[AHADropInfoViewController class]],
			 @"Internal error: root view controller must be drop info");

	_infoViewController = self.viewControllers[0];
	_infoViewController.dropInfoDelegate = self;

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
		__weak AHADropViewController* weakSelf = self;
		[_dropDelegate renderCoverImageForPiece:_dropPieceData completion:^(UIImage* _Nullable image) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf coverImageDidArrive:image];
		}];
	}
}

- (void)coverImageDidArrive:(UIImage*)image {
	NSAssert(_infoViewController != nil,
			 @"Internal error: info view must be set");

	[_infoViewController setDefaultCoverImage:image];
}

- (void)coverImageDidCompleteUpload:(NSURL*)url error:(NSError*)error {
	_coverImageURL = url;
	_waitingForCoverImage = NO;

	[self tick];
}

- (void)fetchMixStem {
	_waitingForMixStem = YES;
	__weak AHADropViewController* weakSelf = self;

	[_dropDelegate renderMixStemForPiece:_dropPieceData completion:^(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error) {
		AHADropViewController* strongSelf = weakSelf;

		[strongSelf mixStemDidArrive:bundle error:error];
	}];
}

- (void)mixStemDidArrive:(AHAAudioDataBundle*)bundle error:(NSError*)fetchError {
	NSAssert([NSThread isMainThread],
			 @"Must call completion handlers on main queue");

	if (bundle) {
		__weak AHADropViewController* weakSelf = self;
		AHAUploadAssetData(_configuration, bundle.data, ^(NSURL *url, NSError *uploadError) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf mixStemDidCompleteUpload:bundle url:url error:uploadError];
		});
	}
}

- (void)mixStemDidCompleteUpload:(AHAAudioDataBundle*)bundle url:(NSURL*)url error:(NSError*)error {
	_mixStemBundle = bundle;
	_mixStemURL = url;
	_waitingForMixStem = NO;

	[self tick];
}

- (void)fetchPreviewAudio {
	if ([_dropDelegate respondsToSelector:@selector(renderPreviewAudioForPiece:completion:)]) {
		_waitingForPreviewAudio = YES;
		__weak AHADropViewController* weakSelf;

		[_dropDelegate renderPreviewAudioForPiece:_dropPieceData completion:^(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf previewAudioDidArrive:bundle error:error];
		}];
	}
}

- (void)previewAudioDidArrive:(AHAAudioDataBundle*)bundle error:(NSError*)fetchError {
	NSAssert([NSThread isMainThread],
			 @"Must call completion handlers on main queue");

	if (bundle) {
		__weak AHADropViewController* weakSelf = self;
		AHAUploadAssetData(_configuration, bundle.data, ^(NSURL *url, NSError *uploadError) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf previewAudioDidCompleteUpload:bundle url:url error:uploadError];
		});
	}
}

- (void)previewAudioDidCompleteUpload:(AHAAudioDataBundle*)bundle url:(NSURL*)url error:(NSError*)error {
	_previewAudioBundle = bundle;
	_previewAudioURL = url;
	_waitingForPreviewAudio = NO;

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
	for (NSUUID* uuid in _dropPieceData.basedOnPieceIDs) {
		[basedOnPieces addObject:uuid.UUIDString];
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

	__weak AHADropViewController* weakSelf = self;
	AHAGraphQLQuery(_configuration, kCreatePieceQuery, @{ @"piece": piece }, ^(NSDictionary *response, NSError *error) {
		AHADropViewController* strongSelf = weakSelf;

		[strongSelf createPieceFromPartsDidComplete:response error:error];
	});
}

- (void)createPieceFromPartsDidComplete:(NSDictionary*)piece error:(NSError*)error {
	if (piece != nil) {
		_createdPiece = piece;
		_waitingForCreatePiece = NO;

		[self tick];
	}
}

#pragma mark - Private methods (state machine)

- (void)tick {
	int waitingParts = ((_waitingForMixStem ? 1 : 0)
						+ (_waitingForPieceInfo ? 1 : 0)
						+ (_waitingForCoverImage ? 1 : 0)
						+ (_waitingForPreviewAudio ? 1 : 0));

	BOOL pieceCreated = !!_createdPiece;

	if (waitingParts == 0 && !_waitingForCreatePiece && !pieceCreated) {
		[self createPieceFromParts];
	}
	else if (pieceCreated) {
		NSAssert(_progressViewController != nil,
				 @"Internal error: no progress view controller available");
		NSLog(@"Everything is done: %@", _createdPiece);
		[_progressViewController advanceToDropDone];
	}
}

#pragma mark - AHADropInfoViewControllerDelegate

- (void)dropInfoViewControllerDidCommitTitle:(NSString*)title
								 description:(NSString*)description
									  listed:(BOOL)isListed
								  coverImage:(UIImage*)coverImage {
	NSAssert(title != nil, @"Internal error: must commit title");
	NSAssert(description != nil, @"Internal error: must commit description");
	NSAssert(_waitingForPieceInfo, @"Internal error: can't commit piece info twice");

	_committedTitle = title;
	_committedDescription = description;
	_committedListed = isListed;
	_committedCoverImage = coverImage;
	_waitingForPieceInfo = NO;

	if (_committedCoverImage != nil) {
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
	NSAssert(dropProgressViewController != nil, @"Internal error: no drop progress view controller provided");
	NSAssert(_progressViewController == nil, @"Internal error: transition to progress view controller multiple times");

	_progressViewController = dropProgressViewController;
}

@end
