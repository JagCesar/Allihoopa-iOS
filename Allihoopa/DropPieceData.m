#import "DropPieceData.h"

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

@end


@implementation AHADropPieceData {
	NSString* _defaultTitle;
	NSString* _description;
	BOOL _listed;

	NSInteger _lengthMicroseconds;
	AHAFixedTempo* _tempo;
	AHALoopMarkers* _loopMarkers;
	AHATimeSignature* _timeSignature;

	NSArray* _basedOnPieceIDs;
}

- (NSString *)defaultTitle { return _defaultTitle; }
- (NSString *)description { return _description; }
- (BOOL)listed { return _listed; }

- (NSInteger)lengthMicroseconds { return _lengthMicroseconds; }
- (AHAFixedTempo *)tempo { return _tempo; }
- (AHALoopMarkers *)loopMarkers { return _loopMarkers; }
- (AHATimeSignature *)timeSignature { return _timeSignature; }

- (NSArray<NSUUID *> *)basedOnPieceIDs { return _basedOnPieceIDs; }

- (instancetype)initWithDefaultTitle:(NSString *)defaultTitle
				  lengthMicroseconds:(NSInteger)lengthMicroseconds
							   tempo:(AHAFixedTempo *)tempo
						 loopMarkers:(AHALoopMarkers *)loopMarkers
					   timeSignature:(AHATimeSignature *)timeSignature
					 basedOnPieceIDs:(NSArray<NSUUID *> *)basedOnPieceIDs {
	if ((self = [super init])) {
		NSAssert(defaultTitle != nil, @"Default title must not be nil");
		NSAssert(basedOnPieceIDs != nil, @"Based on piece IDs must not be nil");

		_defaultTitle = [defaultTitle copy];

		_lengthMicroseconds = lengthMicroseconds;
		_tempo = tempo;
		_loopMarkers = loopMarkers;
		_timeSignature = timeSignature;

		_basedOnPieceIDs = [basedOnPieceIDs copy];
	}

	return self;
}

@end
