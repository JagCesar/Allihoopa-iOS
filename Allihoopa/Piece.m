#import "Piece.h"
#import "Piece+Internal.h"

#import "DropPieceData.h"
#import "Errors.h"

static id CoerceNull(id value) {
	if (value == [NSNull null]) {
		return nil;
	}

	return value;
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

- (instancetype)initWithPieceNode:(NSDictionary*)pieceNode error:(NSError* __autoreleasing *)outError {
	NSAssert(outError != nil, @"No error destination provided");

	if ((self = [super init])) {
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

@end
