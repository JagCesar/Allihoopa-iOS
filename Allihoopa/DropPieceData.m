#import "DropPieceData.h"
#import "DropPieceData+Internal.h"

#import "Errors.h"

@implementation AHAPieceID {
	NSString* _pieceID;
}

- (NSString*)pieceID { return _pieceID; }

- (instancetype)initWithPieceID:(NSString *)pieceID {
	if ((self = [super init])) {
		_pieceID = [pieceID copy];
	}

	return self;
}

- (BOOL)isEqual:(id)object {
	if ([object isKindOfClass:[AHAPieceID class]]) {
		AHAPieceID* other = object;

		return [_pieceID isEqualToString:other->_pieceID];
	}

	return NO;
}

- (NSUInteger)hash {
	return _pieceID.hash;
}

@end

@implementation AHAPieceID (Internal)

- (NSString *)pieceID { return _pieceID; }

@end

@implementation AHAFixedTempo {
	double _fixedTempo;
}

- (double)fixedTempo { return _fixedTempo; }

- (instancetype)initWithFixedTempo:(double)fixedTempo {
	if ((self = [super init])) {
		_fixedTempo = fixedTempo;
	}

	return self;
}

- (NSError*)validate {
	if (_fixedTempo < 1) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceTempoTooLow
							   userInfo:@{ NSLocalizedDescriptionKey: @"tempo: the tempo needs to be at least 1 BPM" }];
	}

	if (_fixedTempo > 999.999) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceTempoTooHigh
							   userInfo:@{ NSLocalizedDescriptionKey: @"tempo: the tempo needs to be lower than 999.999 BPM" }];
	}

	return nil;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<AHAFixedTempo fixedTempo=%g>", _fixedTempo];
}

@end


@implementation AHALoopMarkers {
	NSInteger _startMicroseconds;
	NSInteger _endMicroseconds;
}

- (NSInteger)startMicroseconds { return _startMicroseconds; }
- (NSInteger)endMicroseconds { return _endMicroseconds; }

- (instancetype)initWithStartMicroseconds:(NSInteger)startMicroseconds
						  endMicroseconds:(NSInteger)endMicroseconds {
	if ((self = [super init])) {
		_startMicroseconds = startMicroseconds;
		_endMicroseconds = endMicroseconds;
	}

	return self;
}

- (NSError*)validateWithPieceLength:(NSInteger)pieceLength {
	if (_startMicroseconds < 0) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceInvalidLoopMarkers
							   userInfo:@{ NSLocalizedDescriptionKey: @"loopMarkers: loop start position can not be negative" }];
	}

	if (_endMicroseconds > pieceLength) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceInvalidLoopMarkers
							   userInfo:@{ NSLocalizedDescriptionKey: @"loopMarkers: loop end position can not be after the end of the piece" }];
	}

	if (_startMicroseconds >= _endMicroseconds) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceInvalidLoopMarkers
							   userInfo:@{ NSLocalizedDescriptionKey: @"loopMarkers: loop start position must be before end position" }];
	}

	return nil;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<AHALoopMarkers start=%li end=%li>",
			_startMicroseconds,
			_endMicroseconds];
}

@end


@implementation AHATimeSignature {
	NSInteger _upper;
	NSInteger _lower;
}

- (NSInteger)upper { return _upper; }
- (NSInteger)lower { return _lower; }

- (instancetype)initWithUpper:(NSInteger)upper lower:(NSInteger)lower {
	if ((self = [super init])) {
		_upper = upper;
		_lower = lower;
	}

	return self;
}

- (NSError*)validate {
	if (_upper < 1 || _upper > 16) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceInvalidTimeSignature
							   userInfo:@{ NSLocalizedDescriptionKey: @"timeSignature: upper numeral must be between 1 and 16" }];
	}

	if (_lower != 2 && _lower != 4 && _lower != 8 && _lower != 16) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceInvalidTimeSignature
							   userInfo:@{ NSLocalizedDescriptionKey: @"timeSignature: lower numeral must be 2, 4, 8, or 16" }];
	}

	return nil;
}

- (NSString *)description {
	return [NSString stringWithFormat:@"<AHATimeSignature upper=%li lower=%li>",
			_upper, _lower];
}

@end


@implementation AHADropPieceData {
	NSString* _defaultTitle;

	NSInteger _lengthMicroseconds;
	AHAFixedTempo* _tempo;
	AHALoopMarkers* _loopMarkers;
	AHATimeSignature* _timeSignature;

	NSArray* _basedOnPieceIDs;
}

- (NSString*)defaultTitle { return _defaultTitle; }

- (NSInteger)lengthMicroseconds { return _lengthMicroseconds; }
- (AHAFixedTempo*)tempo { return _tempo; }
- (AHALoopMarkers*)loopMarkers { return _loopMarkers; }
- (AHATimeSignature*)timeSignature { return _timeSignature; }

- (NSArray<NSUUID*>*)basedOnPieceIDs { return _basedOnPieceIDs; }

- (instancetype)initWithDefaultTitle:(NSString*)defaultTitle
				  lengthMicroseconds:(NSInteger)lengthMicroseconds
							   tempo:(AHAFixedTempo*)tempo
						 loopMarkers:(AHALoopMarkers*)loopMarkers
					   timeSignature:(AHATimeSignature*)timeSignature
					 basedOnPieceIDs:(NSArray<AHAPieceID*>*)basedOnPieceIDs
							   error:(NSError* __autoreleasing *)outValidationError {
	if ((self = [super init])) {
		if (!outValidationError) {
			AHARaiseInvalidUsageException(@"Must pass validation error to initializer");
		}

		_defaultTitle = [defaultTitle copy];

		_lengthMicroseconds = lengthMicroseconds;
		_tempo = tempo;
		_loopMarkers = loopMarkers;
		_timeSignature = timeSignature;

		_basedOnPieceIDs = [basedOnPieceIDs copy];

		NSError* validationError = [self validate];
		if (validationError) {
			*outValidationError = validationError;
			return nil;
		}
	}

	return self;
}

- (NSError*)validate {
	if (!_defaultTitle || _defaultTitle.length < 1) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceTitleTooShort
							   userInfo:@{ NSLocalizedDescriptionKey: @"defaultTitle: title needs to be at least one character" }];
	}
	if ([_defaultTitle lengthOfBytesUsingEncoding:NSUTF32StringEncoding] / 4 > 50) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceTitleTooLong
							   userInfo:@{ NSLocalizedDescriptionKey: @"defaultTitle: title needs to be 50 characters or shorter" }];
	}

	if (_lengthMicroseconds <= 0) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceTooShort
							   userInfo:@{ NSLocalizedDescriptionKey: @"lengthMicroseconds: piece is too short" }];
	}
	else if (_lengthMicroseconds > 1200000000) {
		return [NSError errorWithDomain:AHAAllihoopaErrorDomain
								   code:AHAErrorPieceTooLong
							   userInfo:@{ NSLocalizedDescriptionKey: @"lengthMicroseconds: piece is too long, it must be less than 20 minutes" }];
	}

	NSError* err = [_tempo validate];
	if (err) {
		return err;
	}

	err = [_loopMarkers validateWithPieceLength:_lengthMicroseconds];
	if (err) {
		return err;
	}

	err = [_timeSignature validate];
	if (err) {
		return err;
	}

	return nil;
}

@end
