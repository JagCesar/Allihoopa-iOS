@import XCTest;

#import "../Allihoopa/DropPieceData.h"
#import "../Allihoopa/Piece.h"
#import "../Allihoopa/Piece+Internal.h"

@interface ImportPieceTests : XCTestCase
@end

static NSDictionary* GetTestData(NSString* fileName) {
	NSString* path = [[NSBundle bundleForClass:[ImportPieceTests class]] pathForResource:fileName ofType:@"json"];
	NSCAssert(path != nil, @"File %@.json not found", fileName);

	NSData* data = [NSData dataWithContentsOfFile:path];
	NSCAssert(data != nil, @"Data could not be read from %@.json", fileName);

	NSDictionary* obj = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:nil];
	NSCAssert(obj != nil, @"Malformed JSON in %@", fileName);
	NSCAssert([obj isKindOfClass:[NSDictionary class]], @"Top level entity in %@.json must be an object", fileName);

	return obj[@"data"];
}


@implementation ImportPieceTests

- (void)testRegularPiece01 {
	NSError* error;
	AHAPiece* piece = [[AHAPiece alloc] initWithPieceNode:GetTestData(@"piece_01.valid")[@"piece"]
													error:&error];

	XCTAssertNil(error);

	XCTAssertEqualObjects(piece.pieceID,
						  [[AHAPieceID alloc] initWithPieceID:@"7d602eec-0a79-4e63-803a-cc873d1600ff"]);
	XCTAssertEqualObjects(piece.title, @"Just #Sketch");
	XCTAssertEqualObjects(piece.pieceDescription,
						  @"Dope beat by #AOS this is more of a #sketch #freestyle just a short ditty, lol #hiphop #buildonthis #collab");
	XCTAssertEqualObjects(piece.createdAt, [NSDate dateWithTimeIntervalSince1970:1478424515]);
	XCTAssertEqualObjects(piece.url,
						  [NSURL URLWithString:@"https://allihoopa.com/s/gwmMAjgI"]);
	XCTAssertEqualObjects(piece.authorUsername, @"amshinobi");
	XCTAssertEqual(piece.lengthMicroseconds, 262154000);
	XCTAssertEqual(piece.tempo.fixedTempo, 130);
	XCTAssertNil(piece.loop);
	XCTAssertEqual(piece.timeSignature.upper, 4);
	XCTAssertEqual(piece.timeSignature.lower, 4);
}

- (void)testRegularPiece02 {
	NSError* error;
	AHAPiece* piece = [[AHAPiece alloc] initWithPieceNode:GetTestData(@"piece_02.valid")[@"piece"]
													error:&error];

	XCTAssertNil(error);

	XCTAssertEqualObjects(piece.pieceID,
						  [[AHAPieceID alloc] initWithPieceID:@"e6e3af17-85d6-474e-a5a6-22135a0332c6"]);
	XCTAssertEqualObjects(piece.title, @"Style - needs a lead!");
	XCTAssertEqualObjects(piece.pieceDescription,
						  @"Add a lead! Would love to hear what you come up with on this simple chord progression.");
	XCTAssertEqualObjects(piece.createdAt, [NSDate dateWithTimeIntervalSince1970:1475749283]);
	XCTAssertEqualObjects(piece.url,
						  [NSURL URLWithString:@"https://allihoopa.com/s/Sk9ieVZH"]);
	XCTAssertEqualObjects(piece.authorUsername, @"Leo");
	XCTAssertEqual(piece.lengthMicroseconds, 38857000);
	XCTAssertEqual(piece.tempo.fixedTempo, 105);
	XCTAssertEqual(piece.loop.startMicroseconds, 18285714);
	XCTAssertEqual(piece.loop.endMicroseconds, 36571428);
	XCTAssertEqual(piece.timeSignature.upper, 4);
	XCTAssertEqual(piece.timeSignature.lower, 4);
}

- (void)testRegularPiece03 {
	NSError* error;
	AHAPiece* piece = [[AHAPiece alloc] initWithPieceNode:GetTestData(@"piece_03.valid")[@"piece"]
													error:&error];

	XCTAssertNil(error);

	XCTAssertEqualObjects(piece.pieceID,
						  [[AHAPieceID alloc] initWithPieceID:@"4a6d3488-3ce0-4fde-b24e-a2483ef02562"]);
	XCTAssertEqualObjects(piece.title, @"For Love");
	XCTAssertEqualObjects(piece.pieceDescription,
						  @"It isn't that hard to see. Love really is everywhere. ");
	XCTAssertEqualObjects(piece.createdAt, [NSDate dateWithTimeIntervalSince1970:1436070465]);
	XCTAssertEqualObjects(piece.url,
						  [NSURL URLWithString:@"https://allihoopa.com/s/Q9ZuA5ii"]);
	XCTAssertEqualObjects(piece.authorUsername, @"ellenmomeara89");
	XCTAssertEqual(piece.lengthMicroseconds, 202647000);
	XCTAssertNil(piece.tempo);
	XCTAssertNil(piece.loop);
	XCTAssertNil(piece.timeSignature);
}

- (void)testMissingPiece01 {
	NSError* error;
	AHAPiece* piece = [[AHAPiece alloc] initWithPieceNode:GetTestData(@"piece_01.missing")[@"piece"]
													error:&error];

	XCTAssertNotNil(error);
	XCTAssertNil(piece);
}

@end
