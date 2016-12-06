#import "DropCoordinator.h"

#import <UIKit/UIKit.h>
#import <Accounts/Accounts.h>
#import <Social/Social.h>

#import "../DropDelegate.h"
#import "../Errors.h"
#import "../Allihoopa+Internal.h"
#import "../APICommunication.h"
#import "../DataBundle.h"
#import "../Promise.h"
#import "../DropPieceData.h"

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


@implementation AHADropCoordinator {
	AHAConfiguration* _configuration;
	__weak id<AHADropCoordinatorDelegate> _delegate;
	__weak id<AHADropDelegate> _dropDelegate;
	AHADropPieceData* _dropPieceData;

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
}

- (instancetype)initWithConfiguration:(AHAConfiguration *)configuration
				  coordinatorDelegate:(id<AHADropCoordinatorDelegate>)coordinatorDelegate
						 dropDelegate:(id<AHADropDelegate>)dropDelegate
							pieceData:(AHADropPieceData *)dropPieceData
{
	if ((self = [super init])) {
		NSAssert(configuration != nil, @"Configuration must be provided");
		NSAssert(coordinatorDelegate != nil, @"Coordinator delegate must be provided");
		NSAssert(dropDelegate != nil, @"Drop delegate must be provided");
		NSAssert(dropPieceData != nil, @"Drop piece data must be provided");

		_configuration = configuration;
		_delegate = coordinatorDelegate;
		_dropDelegate = dropDelegate;
		_dropPieceData = dropPieceData;
	}

	return self;
}

#pragma mark - Public methods

- (void)runDropFlow {
	_pieceInfoPromise = [[AHAPromise alloc] init];
	_mixStemPromise = [[AHAPromise alloc] init];
	_previewAudioPromise = [[AHAPromise alloc] init];
	_downloadedCoverImagePromise = [[AHAPromise alloc] init];

	__weak AHADropCoordinator* weakSelf = self;

	[_pieceInfoPromise onComplete:^(__unused id value, __unused NSError *error) {
		AHADropCoordinator* strongSelf = weakSelf;

		if (strongSelf) {
			[strongSelf->_delegate segueToProgressViewController];
		}
	}];

	_coverImageURLPromise = [_pieceInfoPromise map:^AHAPromise *(AHADropInfo *value) {
		AHADropCoordinator* strongSelf = weakSelf;

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
			 AHADropCoordinator* strongSelf = weakSelf;

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
		  AHADropCoordinator* strongSelf = weakSelf;

		  if (strongSelf != nil) {
			  strongSelf->_createdPiece = value;
			  [strongSelf->_delegate didCreatePiece:value];
			  return [[AHAPromise alloc]
					  initWithPromises:@[ [strongSelf downloadCoverImage],
										  [strongSelf shareToSocialServices:dropInfo] ]];
		  }

		  return nil;
	  }]
	 onSuccess:^(NSArray* results) {
		 AHALog(@"Auxiliary promises complete - advance to drop done");
		 AHADropCoordinator* strongSelf = weakSelf;

		 if (strongSelf) {
			 strongSelf->_downloadedCoverImage = results[0];

			 id<AHADropCoordinatorDelegate> delegate = strongSelf->_delegate;
			 [delegate didDownloadFinalCoverImage:results[0]];
			 [delegate segueToDropDoneViewController];
		 }
	 } failure:^(__unused NSError *error) {
		 AHALog(@"Error occurred in drop chain: %@", error);
		 AHADropCoordinator* strongSelf = weakSelf;

		 if (strongSelf) {
			 [strongSelf->_delegate segueToErrorViewController];
		 }
	 }];

	[self fetchDefaultCoverImage];
	[self fetchMixStem];
	[self fetchPreviewAudio];
}

- (void)commitPieceInfo:(AHADropInfo *)dropInfo {
	NSAssert(dropInfo != nil, @"Must provide drop info");

	[_pieceInfoPromise resolveWithValue:dropInfo];
}

#pragma mark - Private methods (delegate data fetching)

- (void)fetchDefaultCoverImage {
	id<AHADropDelegate> delegate = _dropDelegate;
	if ([delegate respondsToSelector:@selector(renderCoverImageForPiece:completion:)]) {
		AHALog(@"Fetching default cover image from application");

		__weak AHADropCoordinator* weakSelf = self;
		[delegate renderCoverImageForPiece:_dropPieceData completion:^(UIImage* _Nullable image) {
			[weakSelf coverImageDidArrive:image];
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
	[_delegate defaultCoverImageDidArrive:image];
}

- (void)fetchMixStem {
	AHALog(@"Fetching mix stem from application");

	__weak AHADropCoordinator* weakSelf = self;

	[_dropDelegate renderMixStemForPiece:_dropPieceData completion:^(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error) {
		[weakSelf mixStemDidArrive:bundle error:error];
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
		__weak AHADropCoordinator* weakSelf = self;
		[AHAUploadAssetData(_configuration, bundle.data) onComplete:^(NSURL *url, NSError *uploadError) {
			[weakSelf mixStemDidCompleteUpload:bundle url:url error:uploadError];
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
	id<AHADropDelegate> delegate = _dropDelegate;
	if ([delegate respondsToSelector:@selector(renderPreviewAudioForPiece:completion:)]) {
		AHALog(@"Fetching preview audio from application");
		__weak AHADropCoordinator* weakSelf = self;

		[delegate renderPreviewAudioForPiece:_dropPieceData completion:^(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error) {
			[weakSelf previewAudioDidArrive:bundle error:error];
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

		__weak AHADropCoordinator* weakSelf = self;
		[AHAUploadAssetData(_configuration, bundle.data) onComplete:^(NSURL *url, NSError *uploadError) {
			[weakSelf previewAudioDidCompleteUpload:bundle url:url error:uploadError];
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

		__weak AHADropCoordinator* weakSelf = self;
		[p onFailure:^(__unused NSError *error) {
			[weakSelf showSocialServicePostingError:@"Twitter"];
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

		__weak AHADropCoordinator* weakSelf = self;
		[p onFailure:^(__unused NSError *error) {
			[weakSelf showSocialServicePostingError:@"Facebook"];
		}];

		[promises addObject:p];
	}

	return [[AHAPromise alloc] initWithPromises:promises];
}

- (void)showSocialServicePostingError:(NSString*)serviceName {
	[_delegate socialQuickPostingFailedForNetwork:serviceName];
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



@implementation AHADropInfo

- (instancetype)initWithTitle:(NSString *)title
			 pieceDescription:(NSString *)pieceDescription
					   listed:(BOOL)isListed
				   coverImage:(UIImage *)coverImage
			  facebookAccount:(ACAccount *)facebookAccount
	facebookAccountCredential:(ACAccountCredential *)facebookAccountCredential
			   twitterAccount:(ACAccount *)twitterAccount
{
	if ((self = [super init])) {
		_title = title;
		_pieceDescription = pieceDescription;
		_isListed = isListed;
		_coverImage = coverImage;
		_facebookAccount = facebookAccount;
		_facebookAccountCredential = facebookAccountCredential;
		_twitterAccount = twitterAccount;
	}

	return self;
}

@end
