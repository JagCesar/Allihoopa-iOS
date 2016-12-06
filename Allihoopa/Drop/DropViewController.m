#import "DropViewController.h"

#import <Social/Social.h>
#import <Accounts/Accounts.h>

#import "../AllihoopaSDK.h"
#import "../Allihoopa+Internal.h"

#import "../DropDelegate.h"
#import "../Configuration.h"
#import "../APICommunication.h"
#import "../Errors.h"
#import "../Promise.h"

#import "DropInfoViewController.h"
#import "DropProgressViewController.h"
#import "DropDoneViewController.h"
#import "AssetUpload.h"

static NSString* const kCreatePieceQuery = @"\
mutation($piece: PieceInput!) {\
  dropPiece(piece: $piece) {\
    piece {\
      title\
      url\
      description\
      shortId\
      coverImage(position: 10 withFallback: true) {\
        url\
      }\
    }\
  }\
}\
";

static id CoerceNull(id value) {
	if (value == [NSNull null]) {
		return nil;
	}

	return value;
}

@interface AHAUploadedBundle : NSObject

@property (nonatomic, readonly) AHAAudioDataBundle* bundle;
@property (nonatomic, readonly) NSURL* url;

- (instancetype)initWithBundle:(AHAAudioDataBundle*)bundle url:(NSURL*)url;

@end



@interface AHADropViewController () <AHADropInfoViewControllerDelegate, AHADropProgressViewControllerDelegate>
@end

@implementation AHADropViewController {
	AHADropInfoViewController* _infoViewController;
	AHADropProgressViewController* _progressViewController;
	AHADropDoneViewController* _doneViewController;

	BOOL _hasBeenPresented;

	AHAPromise<AHADropInfo*>* _pieceInfoPromise;

	BOOL _gotCoverImageFromApplication;
	AHAPromise<NSURL*>* _coverImageURLPromise;

	BOOL _gotMixStemFromApplication;
	AHAPromise<AHAUploadedBundle*>* _mixStemPromise;

	BOOL _gotPreviewAudioFromApplication;
	AHAPromise<AHAUploadedBundle*>* _previewAudioPromise;

	NSDictionary* _createdPiece;

	UIImage* _downloadedCoverImage;
	AHAPromise<UIImage*>* _downloadedCoverImagePromise;

	BOOL _dropSuccessful;
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
	_infoViewController.configuration = _configuration;

	[_infoViewController setDefaultTitle:_dropPieceData.defaultTitle];

	[self runDropFlow];
	[self fetchDefaultCoverImage];
}

- (void)viewDidAppear:(__unused BOOL)animated {
	if (!_hasBeenPresented) {
		_hasBeenPresented = YES;

		__weak AHADropViewController* weakSelf = self;
		[AHAAllihoopaSDK authenticate:^(BOOL successful) {
			AHADropViewController* strongSelf = weakSelf;

			if (strongSelf) {
				if (successful) {
					[strongSelf fetchMixStem];
					[strongSelf fetchPreviewAudio];
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
	id<AHADropDelegate> delegate = _dropDelegate;
	if ([delegate respondsToSelector:@selector(dropViewControllerForPieceWillClose:afterSuccessfulDrop:)]) {
		[delegate dropViewControllerForPieceWillClose:_dropPieceData
								  afterSuccessfulDrop:_dropSuccessful];
	}

	if (_dismissWhenCloseTapped) {
		[self dismissViewControllerAnimated:YES completion:nil];
	}
}


#pragma mark - Private methods (Drop state machine logic)

- (void)runDropFlow {
	_pieceInfoPromise = [[AHAPromise alloc] init];
	_mixStemPromise = [[AHAPromise alloc] init];
	_previewAudioPromise = [[AHAPromise alloc] init];
	_downloadedCoverImagePromise = [[AHAPromise alloc] init];

	__weak AHADropViewController* weakSelf = self;

	[_pieceInfoPromise onComplete:^(__unused id value, __unused NSError *error) {
		AHADropViewController* strongSelf = weakSelf;

		if (strongSelf) {
			[strongSelf->_infoViewController segueToProgressViewController];
		}
	}];

	_coverImageURLPromise = [_pieceInfoPromise map:^AHAPromise *(AHADropInfo *value) {
		AHADropViewController* strongSelf = weakSelf;

		if (strongSelf) {
			if (value.coverImage) {
				return AHAUploadAssetData(strongSelf->_configuration, UIImagePNGRepresentation(value.coverImage));
			}
			else {
				return [[AHAPromise alloc] initWithValue:nil];
			}
		}

		return nil;
	}];

	__block AHADropInfo* dropInfo = nil;

	[[[[[[[AHAPromise<NSArray*> alloc]
		  initWithPromises:@[_mixStemPromise,
							 _previewAudioPromise,
							 _coverImageURLPromise,
							 _pieceInfoPromise]]
		 map:^AHAPromise *(NSArray* parts) {
			 AHALog(@"All URLs/parts resolved");
			 AHADropViewController* strongSelf = weakSelf;

			 if (strongSelf != nil) {
				 AHAUploadedBundle* uploadedMixStem = CoerceNull(parts[0]);
				 AHAUploadedBundle* uploadedPreviewAudio = CoerceNull(parts[1]);
				 NSURL* coverImageURL = CoerceNull(parts[2]);
				 dropInfo = parts[3];

				 return [strongSelf createPieceFromInfo:dropInfo
										uploadedMixStem:uploadedMixStem
								   uploadedPreviewAudio:uploadedPreviewAudio
										  coverImageURL:coverImageURL];
			 }

			 return nil;
		 }]
		filter:^BOOL(id value) {
			return (value
					&& value[@"dropPiece"]
					&& [value[@"dropPiece"] isKindOfClass:[NSDictionary class]]
					&& value[@"dropPiece"][@"piece"]
					&& [value[@"dropPiece"][@"piece"] isKindOfClass:[NSDictionary class]]);
		}]
	   mapValue:^id(id value) {
		   return value[@"dropPiece"][@"piece"];
	   }]
	  map:^AHAPromise *(id value) {
		  AHALog(@"Piece dropped, uploading cover image and sharing to services");
		  AHADropViewController* strongSelf = weakSelf;

		  if (strongSelf != nil) {
			  strongSelf->_createdPiece = value;
			  return [[AHAPromise alloc]
					  initWithPromises:@[ [strongSelf downloadCoverImage],
										  [strongSelf shareToSocialServices:dropInfo] ]];
		  }

		  return nil;
	  }]
	 onSuccess:^(NSArray* results) {
		 AHALog(@"Auxiliary promises complete - advance to drop done");
		 AHADropViewController* strongSelf = weakSelf;

		 if (strongSelf) {
			 strongSelf->_dropSuccessful = YES;
			 strongSelf->_downloadedCoverImage = results[0];

			 [strongSelf->_progressViewController advanceToDropDone];
		 }
	 } failure:^(__unused NSError *error) {
		 AHALog(@"Error occurred in drop chain: %@", error);
		 AHADropViewController* strongSelf = weakSelf;

		 if (strongSelf) {
			 [strongSelf performSegueWithIdentifier:@"dropError" sender:nil];
		 }
	 }];
}


#pragma mark - Private methods (delegate data fetching)

- (void)fetchDefaultCoverImage {
	id<AHADropDelegate> delegate = _dropDelegate;
	if ([delegate respondsToSelector:@selector(renderCoverImageForPiece:completion:)]) {
		AHALog(@"Fetching default cover image from application");

		__weak AHADropViewController* weakSelf = self;
		[delegate renderCoverImageForPiece:_dropPieceData completion:^(UIImage* _Nullable image) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf coverImageDidArrive:image];
		}];
	}
}

- (void)coverImageDidArrive:(UIImage*)image {
	if (![NSThread isMainThread]) {
		AHARaiseInvalidUsageException(@"Must call completion handlers on main queue");
	}

	if (_gotCoverImageFromApplication) {
		AHARaiseInvalidUsageException(@"The cover image completion handler can not be called multiple times per piece");
	}

	_gotCoverImageFromApplication = YES;

	AHALog(@"Default cover image arrived from application");
	NSAssert(_infoViewController != nil, @"Info view must be set");

	[_infoViewController setDefaultCoverImage:image];
}

- (void)fetchMixStem {
	AHALog(@"Fetching mix stem from application");

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

	if (_gotMixStemFromApplication) {
		AHARaiseInvalidUsageException(@"The mix stem completion handler can not be called multiple times per piece");
	}

	_gotMixStemFromApplication = YES;

	AHALog(@"Mix stem arrived from application, error: %@", fetchError);

	if (bundle) {
		AHALog(@"Uploading mix stem");
		__weak AHADropViewController* weakSelf = self;
		[AHAUploadAssetData(_configuration, bundle.data) onComplete:^(NSURL *url, NSError *uploadError) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf mixStemDidCompleteUpload:bundle url:url error:uploadError];
		}];
	}
	else if (fetchError) {
		[_mixStemPromise rejectWithError:fetchError];
	}
	else {
		AHARaiseInvalidUsageException(@"Either a mix stem asset bundle or error must be provided");
	}
}

- (void)mixStemDidCompleteUpload:(AHAAudioDataBundle*)bundle url:(NSURL*)url error:(NSError*)error {
	AHALog(@"Mix stem upload completed, error: %@", error);

	if (error) {
		[_mixStemPromise rejectWithError:error];
	}
	else {
		[_mixStemPromise resolveWithValue:[[AHAUploadedBundle alloc] initWithBundle:bundle url:url]];
	}
}

- (void)fetchPreviewAudio {
	id<AHADropDelegate> delegate = self.dropDelegate;
	if ([delegate respondsToSelector:@selector(renderPreviewAudioForPiece:completion:)]) {
		AHALog(@"Fetching preview audio from application");
		__weak AHADropViewController* weakSelf = self;

		[delegate renderPreviewAudioForPiece:_dropPieceData completion:^(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf previewAudioDidArrive:bundle error:error];
		}];
	}
	else {
		[_previewAudioPromise resolveWithValue:nil];
	}
}

- (void)previewAudioDidArrive:(AHAAudioDataBundle*)bundle error:(NSError*)fetchError {
	if (![NSThread isMainThread]) {
		AHARaiseInvalidUsageException(@"Must call completion handlers on main queue");
	}

	if (_gotPreviewAudioFromApplication) {
		AHARaiseInvalidUsageException(@"The preview audio completion handler can not be called multiple times per piece");
	}

	_gotPreviewAudioFromApplication = YES;

	AHALog(@"Preview audio arrived from application, error: %@", fetchError);

	if (bundle) {
		AHALog(@"Uploading preview audio");

		__weak AHADropViewController* weakSelf = self;
		[AHAUploadAssetData(_configuration, bundle.data) onComplete:^(NSURL *url, NSError *uploadError) {
			AHADropViewController* strongSelf = weakSelf;

			[strongSelf previewAudioDidCompleteUpload:bundle url:url error:uploadError];
		}];
	}
	else {
		[_previewAudioPromise rejectWithError:fetchError];
	}
}

- (void)previewAudioDidCompleteUpload:(AHAAudioDataBundle*)bundle url:(NSURL*)url error:(NSError*)error {
	AHALog(@"Preview audio upload completed, error: %@", error);

	if (error) {
		[_previewAudioPromise rejectWithError:error];
	}
	else {
		[_previewAudioPromise resolveWithValue:[[AHAUploadedBundle alloc] initWithBundle:bundle url:url]];
	}
}


#pragma mark - Private methods (piece creation)

- (AHAPromise<NSDictionary*>*)createPieceFromInfo:(AHADropInfo*)dropInfo
								  uploadedMixStem:(AHAUploadedBundle*)uploadedMixStem
							 uploadedPreviewAudio:(AHAUploadedBundle*)uploadedPreviewAudio
									coverImageURL:(NSURL*)coverImageURL
{
	NSMutableDictionary* presentationData = [NSMutableDictionary new];
	presentationData[@"title"] = dropInfo.title;
	presentationData[@"description"] = dropInfo.pieceDescription;
	presentationData[@"isListed"] = @(dropInfo.isListed);

	if (uploadedPreviewAudio) {
		presentationData[@"preview"] = @{ uploadedPreviewAudio.bundle.formatAsString: uploadedPreviewAudio.url.absoluteString };
	}

	if (coverImageURL) {
		presentationData[@"coverImage"] = @{ @"png": coverImageURL.absoluteString };
	}

	NSDictionary* stems = @{ @"mixStem": @{ uploadedMixStem.bundle.formatAsString: uploadedMixStem.url.absoluteString } };

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

	return AHAGraphQLQuery(_configuration, kCreatePieceQuery, @{ @"piece": piece });
}

#pragma mark - Private methods (downloading cover image)

- (AHAPromise<UIImage*>*)downloadCoverImage {
	NSAssert(_createdPiece, @"Piece must be created before cover image can be downloaded");

	NSURLSession* session = [NSURLSession sharedSession];
	NSURL* url = [NSURL URLWithString:_createdPiece[@"coverImage"][@"url"]];

	return [[AHAPromise<UIImage*> alloc] initWithResolver:^(void (^resolve)(UIImage *success), void (^reject)(NSError *error)) {
		NSURLSessionDataTask* task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data,
																					  __unused NSURLResponse * _Nullable response,
																					  NSError * _Nullable error) {
			UIImage* image;
			if (data) {
				image = [UIImage imageWithData:data];
				resolve(image);
			}
			else {
				reject(error);
			}
		}];
		[task resume];
	}];
}

#pragma mark - Private methods (social sharing)

- (AHAPromise*)shareToSocialServices:(AHADropInfo*)dropInfo {
	NSAssert(_createdPiece != nil, @"Piece must be created before posting to social services");


	NSString* post = [NSString stringWithFormat:@"%@ is my latest piece, check it out! %@",
					  _createdPiece[@"title"], _createdPiece[@"url"]];

	NSString* description = _createdPiece[@"description"];
	if (description && (id)description != [NSNull null] && description.length > 0) {
		if (description.length > 140 - 23 - 1) { // Max tweet length - shortened URL - a single space
			description = [[description substringToIndex:140 - 23 - 2] stringByAppendingString:@"…"];
		}

		post = [NSString stringWithFormat:@"%@ %@", description, _createdPiece[@"url"]];
	}

	NSMutableArray<AHAPromise*>* promises = [[NSMutableArray alloc] init];

	if (dropInfo.twitterAccount) {
		AHAPromise* p = [[AHAPromise alloc] initWithResolver:^(void (^resolve)(id success), __unused void (^reject)(NSError *error)) {
			AHALog(@"Posting to Twitter");
			SLRequest* request = [SLRequest requestForServiceType:SLServiceTypeTwitter
													requestMethod:SLRequestMethodPOST
															  URL:[NSURL URLWithString:@"https://api.twitter.com/1.1/statuses/update.json"]
													   parameters:@{@"status": post}];
			request.account = dropInfo.twitterAccount;

			[request performRequestWithHandler:^(__unused NSData *responseData, __unused NSHTTPURLResponse *urlResponse, NSError *error) {
				AHALog(@"Post to Twitter done, error: %@", error);

				if (error) {
					reject(error);
				}
				else {
					resolve(nil);
				}
			}];
		}];

		__weak AHADropViewController* weakSelf = self;
		[p onFailure:^(__unused NSError *error) {
			AHADropViewController* strongSelf = weakSelf;

			if (strongSelf) {
				[strongSelf showSocialServicePostingError:@"Twitter"];
			}
		}];

		[promises addObject:p];
	}

	if (dropInfo.facebookAccount) {
		NSAssert(dropInfo.facebookAccountCredential != nil, @"FB account credential must be present if FB account enabled");

		AHAPromise* p = [[AHAPromise alloc] initWithResolver:^(void (^resolve)(id success), __unused void (^reject)(NSError *error)) {
			AHALog(@"Posting to Facebook");
			SLRequest* request = [SLRequest requestForServiceType:SLServiceTypeFacebook
													requestMethod:SLRequestMethodPOST
															  URL:[NSURL URLWithString:@"https://graph.facebook.com/v2.8/me/feed"]
													   parameters:@{@"message": post,
																	@"access_token": dropInfo.facebookAccountCredential.oauthToken,
																	}];

			request.account = dropInfo.facebookAccount;

			[request performRequestWithHandler:^(__unused NSData *responseData, __unused NSHTTPURLResponse *urlResponse, NSError *error) {
				AHALog(@"Post to Facebook done, error: %@", error);

				if (error) {
					reject(error);
				}
				else {
					resolve(nil);
				}
			}];
		}];

		__weak AHADropViewController* weakSelf = self;
		[p onFailure:^(__unused NSError *error) {
			AHADropViewController* strongSelf = weakSelf;

			if (strongSelf) {
				[strongSelf showSocialServicePostingError:@"Facebook"];
			}
		}];

		[promises addObject:p];
	}

	return [[AHAPromise alloc] initWithPromises:promises];
}

- (void)showSocialServicePostingError:(NSString*)serviceName {
	NSString* message = [NSString stringWithFormat:@"Could not share this piece to %@ :(", serviceName];

	UIAlertController* alert = [UIAlertController alertControllerWithTitle:@"Sharing Error"
																   message:message
															preferredStyle:UIAlertControllerStyleAlert];

	[alert addAction:[UIAlertAction actionWithTitle:@"Okay" style:UIAlertActionStyleCancel handler:^(__unused UIAlertAction * _Nonnull action) {}]];

	[self presentViewController:alert animated:YES completion:nil];
}

#pragma mark - AHADropInfoViewControllerDelegate

- (void)dropInfoViewControllerDidCommit:(AHADropInfo*)dropInfo
{
	AHALog(@"Info view committed piece information");

	NSAssert(dropInfo.title != nil, @"Must commit title");
	NSAssert(dropInfo.pieceDescription != nil, @"Must commit description");

	[_pieceInfoPromise resolveWithValue:dropInfo];
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

@end




@implementation AHAUploadedBundle

- (instancetype)initWithBundle:(AHAAudioDataBundle *)bundle url:(NSURL *)url {
	if ((self = [super init])) {
		NSAssert(bundle != nil, @"Bundle must be provided");
		NSAssert(url != nil, @"URL must be provided");

		_bundle = bundle;
		_url = url;
	}

	return self;
}

@end
