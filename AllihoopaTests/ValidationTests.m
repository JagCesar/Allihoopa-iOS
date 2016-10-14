@import XCTest;

#import "../Allihoopa/DropPieceData.h"
#import "../Allihoopa/Errors.h"

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wunused-value"

@interface ModelTests : XCTestCase
@end

@implementation ModelTests

- (void)testAcceptsMinimalMetadata {
	NSError* outError;
	AHADropPieceData* piece = [[AHADropPieceData alloc]
							   initWithDefaultTitle:@"Default title"
							   lengthMicroseconds:4000000
							   tempo:nil
							   loopMarkers:nil
							   timeSignature:nil
							   basedOnPieceIDs:@[]
							   error:&outError];
	XCTAssertNil(outError);

	XCTAssertEqualObjects(piece.defaultTitle, @"Default title");
	XCTAssertEqual(piece.lengthMicroseconds, 4000000);
	XCTAssertNil(piece.tempo);
	XCTAssertNil(piece.loopMarkers);
	XCTAssertNil(piece.timeSignature);
	XCTAssertEqual(piece.basedOnPieceIDs.count, 0ul);
}

#pragma mark - Piece Length

- (void)testAcceptsExactlyOneMicrosecondPieces {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:1
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testAcceptsExactlyTwentyMinutePieces {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:1200000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testRejectsZeroLength {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:0
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"lengthMicroseconds"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTooShort);
}

- (void)testRejectsNegativeLength {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:-50000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"lengthMicroseconds"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTooShort);
}

- (void)testRejectsLongerThanTwentyMinutes {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:1200000001
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"lengthMicroseconds"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTooLong);
}

#pragma mark - Tempo

- (void)testAcceptsValidTempo {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:50000
											 tempo:[[AHAFixedTempo alloc] initWithFixedTempo:128]
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testAcceptsExactlyOneBPM {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:50000
											 tempo:[[AHAFixedTempo alloc] initWithFixedTempo:1]
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testAcceptsExactly999Dot999BPM {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:50000
											 tempo:[[AHAFixedTempo alloc] initWithFixedTempo:999.999]
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testRejectstTooLowBPM {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:50000
											 tempo:[[AHAFixedTempo alloc] initWithFixedTempo:0]
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"tempo"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTempoTooLow);
}

- (void)testRejectstTooHighBPM {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:50000
											 tempo:[[AHAFixedTempo alloc] initWithFixedTempo:1000]
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"tempo"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTempoTooHigh);
}

#pragma mark - Loop markers

- (void)testAcceptsValidLoopMarkers {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:1000000
																					 endMicroseconds:2000000]
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testAcceptsWholePieceAsLoop {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:0
																					 endMicroseconds:5000000]
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testRejectsLoopStartingBeforeZero {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:-1000
																					 endMicroseconds:5000000]
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"loop"]);
	XCTAssertEqual(outError.code, AHAErrorPieceInvalidLoopMarkers);
}

- (void)testRejectsLoopEndingAfterPieceEnds {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:1000
																					 endMicroseconds:6000000]
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"loop"]);
	XCTAssertEqual(outError.code, AHAErrorPieceInvalidLoopMarkers);
}

- (void)testRejectsReversedLoopMarkers {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:2000000
																					 endMicroseconds:1000000]
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"loop"]);
	XCTAssertEqual(outError.code, AHAErrorPieceInvalidLoopMarkers);
}

- (void)testRejectsEqualLoopMarkers {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:2000000
																					 endMicroseconds:2000000]
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"loop"]);
	XCTAssertEqual(outError.code, AHAErrorPieceInvalidLoopMarkers);
}

#pragma mark - Time signature

- (void)testAcceptsTimeSignature {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:[[AHATimeSignature alloc] initWithUpper:4 lower:4]
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNil(outError);
}

- (void)testRejectsOddLowerNumeral {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:[[AHATimeSignature alloc] initWithUpper:4 lower:5]
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"timeSignature"]);
	XCTAssertEqual(outError.code, AHAErrorPieceInvalidTimeSignature);
}

- (void)testRejectsInvalidUpperNumeral {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:[[AHATimeSignature alloc] initWithUpper:17 lower:4]
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"timeSignature"]);
	XCTAssertEqual(outError.code, AHAErrorPieceInvalidTimeSignature);
}

#pragma mark - Title

#pragma clang diagnostic push
#pragma clang diagnostic ignored "-Wnonnull"
- (void)testRejectsMissingTitle {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:nil
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"title"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTitleTooShort);
}
#pragma clang diagnostic pop

- (void)testRejectsEmptyTitle {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@""
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"title"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTitleTooShort);
}

- (void)testRejectsTooLongTitle {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Synth portland chicharrones, prism chambray ramps aesthetic meh tote bag messenger bag echo park post-ironic. 90s ramps man bun paleo, readymade stumptown truffaut heirloom pinterest."
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[]
											 error:&outError];
	XCTAssertNotNil(outError);
	XCTAssert([outError.localizedDescription containsString:@"title"]);
	XCTAssertEqual(outError.code, AHAErrorPieceTitleTooLong);
}

#pragma mark - Attirbution data

- (void)testAcceptsListOfBasedOnIDs {
	NSError* outError;
	[[AHADropPieceData alloc] initWithDefaultTitle:@"Default title"
								lengthMicroseconds:5000000
											 tempo:nil
									   loopMarkers:nil
									 timeSignature:nil
								   basedOnPieceIDs:@[ [[AHAPieceID alloc] initWithPieceID:@"abcd" ] ]
											 error:&outError];
	XCTAssertNil(outError);
}


@end

#pragma clang diagnostic pop
