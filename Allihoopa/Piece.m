#import "Piece.h"
#import "Piece+Internal.h"

#import "Allihoopa+Internal.h"
#import "APICommunication.h"
#import "DropPieceData.h"
#import "DropPieceData+Internal.h"
#import "Errors.h"

static NSString* const kGetMixStemGraphQLQuery = @"\
query($pieceID: String!, $format: String!) {\
  piece(uuid: $pieceID) {\
    mixStem(fileType: $format) {\
      url\
    }\
  }\
}\
";

static NSString* const kGetPreviewAudioGraphQLQuery = @"\
query($pieceID: String!, $format: String!) {\
  piece(uuid: $pieceID) {\
    previewAudio(fileType: $format) {\
      url\
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

static NSString* AudioFormatToString(AHAAudioFormat format) {
	switch (format) {
		case AHAAudioFormatWave: return @"wav";
		case AHAAudioFormatOggVorbis: return @"ogg";
	}

	AHARaiseInvalidUsageException(@"Invalid audio format");
}

static NSDate* DateFromString(NSString* dateString) {
	NSRegularExpression* fracRegex = [NSRegularExpression regularExpressionWithPattern:@"\\.[0-9]+"
																			   options:(NSRegularExpressionOptions)0
																				 error:nil];
	NSCAssert(fracRegex != nil, @"Date fractional part regex invalid");

	NSString* dateWithoutFrac = [fracRegex stringByReplacingMatchesInString:dateString
																	options:(NSMatchingOptions)0
																	  range:NSMakeRange(0, dateString.length)
															   withTemplate:@""];

	NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
	formatter.dateFormat = @"yyyy-MM-dd'T'HH:mm:ssZ";

	return [formatter dateFromString:dateWithoutFrac];
}

@implementation AHAPiece {
	AHAConfiguration* _configuration;

	AHAPieceID* _pieceID;

	NSString* _title;
	NSString* _description;
	NSDate* _createdAt;
	NSURL* _url;

	NSString* _authorUsername;

	NSURL* _coverImageURL;

	NSInteger _lengthMicroseconds;

	AHAFixedTempo* _tempo;
	AHALoopMarkers* _loopMarkers;
	AHATimeSignature* _timeSignature;
}


- (AHAPieceID*)pieceID { return _pieceID; }
- (NSString*)title { return _title; }
- (NSString*)pieceDescription { return _description; }
- (NSDate*)createdAt { return _createdAt; }
- (NSURL*)url { return _url; }

- (NSString*)authorUsername { return _authorUsername; }

- (NSInteger)lengthMicroseconds { return _lengthMicroseconds; }

- (AHAFixedTempo*)tempo { return _tempo; }
- (AHALoopMarkers*)loop { return _loopMarkers; }
- (AHATimeSignature*)timeSignature { return _timeSignature; }

- (void)downloadMixStemWithFormat:(AHAAudioFormat)format completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion {
	NSDictionary* vars = @{ @"pieceID": _pieceID.pieceID,
							@"format": AudioFormatToString(format),
							};
	AHARetryingGraphQLQuery(_configuration, kGetMixStemGraphQLQuery, vars, 3, 10,
							^BOOL(NSDictionary *response) {
								return CoerceNull(CoerceNull(CoerceNull(response[@"piece"])[@"mixStem"])[@"url"]) != nil;
							},
							^(NSDictionary *response, NSError *getURLError) {
		AHALog(@"Got mix stem URL info: %@", response);

		if (getURLError != nil) {
			completion(nil, getURLError);
		} else {
			NSURLSession* session = [NSURLSession sharedSession];
			NSURL* url = [NSURL URLWithString:response[@"piece"][@"mixStem"][@"url"]];

			NSURLSessionTask* task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable downloadResponse, NSError * _Nullable error) {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(data, error);
				});
			}];
			[task resume];
		}
	});
}

- (void)downloadAudioPreviewWithFormat:(AHAAudioFormat)format completion:(void (^)(NSData * _Nullable, NSError * _Nullable))completion {
	NSDictionary* vars = @{ @"pieceID": _pieceID.pieceID,
							@"format": AudioFormatToString(format),
							};
	AHARetryingGraphQLQuery(_configuration, kGetPreviewAudioGraphQLQuery, vars, 3, 10,
							^BOOL(NSDictionary *response) {
								return CoerceNull(CoerceNull(CoerceNull(response[@"piece"])[@"previewAudio"])[@"url"]) != nil;
							},
							^(NSDictionary *response, NSError *getURLError) {
		AHALog(@"Got audio preview URL info: %@", response);

		if (getURLError != nil) {
			completion(nil, getURLError);
		} else {
			NSURLSession* session = [NSURLSession sharedSession];
			NSURL* url = [NSURL URLWithString:response[@"piece"][@"previewAudio"][@"url"]];

			NSURLSessionTask* task = [session dataTaskWithURL:url completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable downloadResponse, NSError * _Nullable error) {
				dispatch_async(dispatch_get_main_queue(), ^{
					completion(data, error);
				});
			}];
			[task resume];
		}
	});
}

- (void)downloadCoverImage:(void (^)(UIImage * _Nullable, NSError * _Nullable))completion {
	AHALog(@"Cover image URL: %@", _coverImageURL);

	NSURLSession* session = [NSURLSession sharedSession];
	NSURLSessionTask* task = [session dataTaskWithURL:_coverImageURL completionHandler:^(NSData * _Nullable data, __unused NSURLResponse * _Nullable response, NSError * _Nullable error) {
		UIImage* image;

		if (data) {
			image = [UIImage imageWithData:data scale:1.0];
			if (!image) {
				error = [NSError errorWithDomain:AHAAllihoopaErrorDomain
											code:AHAErrorInternalDownloadError
										userInfo:@{ NSLocalizedDescriptionKey: @"Could not parse image data" }];
			}
		}

		dispatch_async(dispatch_get_main_queue(), ^{
			completion(image, error);
		});
	}];
	[task resume];
}

@end

@implementation AHAPiece (Internal)

+ (NSString*)graphQLFragment {
	return @"\
	  {\
		uuid\
		title\
		description\
		createdAt\
		url\
		\
		author {\
		  username\
		}\
		coverImage(position: 0, withFallback: true) {\
		  url\
		}\
		\
		lengthUs\
		tempo\
		loop {\
		  startUs\
		  endUs\
		}\
		timeSignature {\
		  numerator\
		  denominator\
		}\
	  }\
	";
}

- (instancetype)initWithPieceNode:(NSDictionary*)pieceNode
					configuration:(AHAConfiguration*)configuration
							error:(NSError* __autoreleasing *)outError {
	NSAssert(outError != nil, @"No error destination provided");
	NSAssert(configuration != nil, @"No configuration provided");

	if ((self = [super init])) {
		_configuration = configuration;

		if (!CoerceNull(pieceNode)) {
			*outError = [NSError errorWithDomain:AHAAllihoopaErrorDomain
											code:AHAErrorImportPieceNotFound
										userInfo:@{ NSLocalizedDescriptionKey: @"Piece not found" }];
			return nil;
		}

		NSString* pieceIdString = CoerceNull(pieceNode[@"uuid"]);
		if (pieceIdString) {
			_pieceID = [[AHAPieceID alloc] initWithPieceID:pieceIdString];
		}

		_title = CoerceNull(pieceNode[@"title"]);
		_description = CoerceNull(pieceNode[@"description"]);
		if (!_description) {
			_description = @"";
		}

		_createdAt = DateFromString(CoerceNull(pieceNode[@"createdAt"]));

		NSString* urlString = CoerceNull(pieceNode[@"url"]);
		if (urlString) {
			_url = [NSURL URLWithString:urlString];
		}

		NSDictionary* author = CoerceNull(pieceNode[@"author"]);
		if (author) {
			_authorUsername = CoerceNull(author[@"username"]);
		}

		NSDictionary* coverImage = CoerceNull(pieceNode[@"coverImage"]);
		if (coverImage) {
			NSString* coverImageURLString = CoerceNull(coverImage[@"url"]);
			if (coverImageURLString) {
				_coverImageURL = [NSURL URLWithString:coverImageURLString];
			}
		}

		_lengthMicroseconds = [CoerceNull(pieceNode[@"lengthUs"]) integerValue];

		// All required fields populated, check if any of them are nil:
		if (!_pieceID || !_title || !_createdAt || !_url || !_authorUsername || !_coverImageURL || !_lengthMicroseconds) {
			*outError = [NSError errorWithDomain:AHAAllihoopaErrorDomain
											code:AHAErrorInternalAPIError
										userInfo:@{ NSLocalizedDescriptionKey: @"A required field was missing in server response" }];
			return nil;
		}

		NSNumber* tempo = CoerceNull(pieceNode[@"tempo"]);
		if (tempo) {
			if (![tempo isKindOfClass:[NSNumber class]]) {
				*outError = [NSError errorWithDomain:AHAAllihoopaErrorDomain
												code:AHAErrorInternalAPIError
											userInfo:@{ NSLocalizedDescriptionKey: @"Tempo field was invalid in server response" }];
			}
			_tempo = [[AHAFixedTempo alloc] initWithFixedTempo:tempo.doubleValue];
		}

		NSDictionary* loop = CoerceNull(pieceNode[@"loop"]);
		if (loop) {
			NSNumber* start = CoerceNull(loop[@"startUs"]);
			NSNumber* end = CoerceNull(loop[@"endUs"]);

			if (!start || ![start isKindOfClass:[NSNumber class]]
				|| !end || ![end isKindOfClass:[NSNumber class]]) {
				*outError = [NSError errorWithDomain:AHAAllihoopaErrorDomain
												code:AHAErrorInternalAPIError
											userInfo:@{ NSLocalizedDescriptionKey: @"A loop marker field was missing or invalid in server response" }];
			}

			_loopMarkers = [[AHALoopMarkers alloc] initWithStartMicroseconds:start.integerValue
															 endMicroseconds:end.integerValue];
		}

		NSDictionary* timeSignature = CoerceNull(pieceNode[@"timeSignature"]);
		if (timeSignature) {
			NSNumber* upper = CoerceNull(timeSignature[@"numerator"]);
			NSNumber* lower = CoerceNull(timeSignature[@"denominator"]);

			if (!upper || ![upper isKindOfClass:[NSNumber class]]
				|| !lower || ![lower isKindOfClass:[NSNumber class]]) {
				*outError = [NSError errorWithDomain:AHAAllihoopaErrorDomain
												code:AHAErrorInternalAPIError
											userInfo:@{ NSLocalizedDescriptionKey: @"A time signature field was missing or invalid in server response" }];
			}

			_timeSignature = [[AHATimeSignature alloc] initWithUpper:upper.integerValue
															   lower:lower.integerValue];
		}
	}

	return self;
}

@end
