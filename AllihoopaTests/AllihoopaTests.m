//
//  AllihoopaTests.m
//  AllihoopaTests
//
//  Created by Magnus Hallin on 19/09/16.
//  Copyright © 2016 Allihoopa. All rights reserved.
//

#import <XCTest/XCTest.h>

#import "../Allihoopa/Configuration.h"
#import "../Allihoopa/DropPieceData.h"

@interface ConfigurationTests : XCTestCase
@end

@implementation ConfigurationTests

+ (void)setUp {
	srandom((unsigned int)time(NULL));
}

- (void)testSetup {
	AHAConfiguration* configuration = [[AHAConfiguration alloc] init];

	[configuration setupApplicationIdentifier:@"app-identifier" apiKey:@"apiKey"];

	XCTAssertEqualObjects(configuration.applicationIdentifier, @"app-identifier");
	XCTAssertEqualObjects(configuration.apiKey, @"apiKey");
}

- (void)testIdentifierThrowsOnNoSetup {
	AHAConfiguration* configuration = [[AHAConfiguration alloc] init];

	XCTAssertThrows(configuration.applicationIdentifier);
	XCTAssertThrows(configuration.apiKey);
}

- (void)testUpdateConfiguration {
	AHAConfiguration* configuration = [[AHAConfiguration alloc] init];

	NSString* randomString = [NSString stringWithFormat:@"%li", random()];

	XCTAssertNotEqualObjects(configuration.configuration[@"test"], randomString);

	[configuration update:^(NSMutableDictionary<NSString *,id> * _Nonnull config) {
		[config setObject:randomString forKey:@"test"];
	}];

	XCTAssertEqualObjects(configuration.configuration[@"test"], randomString);
}

- (void)testUpdateConfigurationRaises {
	AHAConfiguration* configuration = [[AHAConfiguration alloc] init];

	NSString* randomString = [NSString stringWithFormat:@"%li", random()];

	XCTAssertNotEqualObjects(configuration.configuration[@"test"], randomString);

	XCTAssertThrows([configuration update:^(NSMutableDictionary<NSString *,id> * _Nonnull config) {
		[config setObject:randomString forKey:@"test"];
		@throw [NSException exceptionWithName:@"AHATestException" reason:@"Testing" userInfo:nil];
	}]);

	XCTAssertNotEqualObjects(configuration.configuration[@"test"], randomString);
}

@end


@interface ModelTests : XCTestCase
@end

@implementation ModelTests

- (void)testAccessors {
	AHADropPieceData* piece = [[AHADropPieceData alloc] initWithDefaultTitle:@"piece title"
														  lengthMicroseconds:1234
																	   tempo:[[AHAFixedTempo alloc] initWithFixedTempo:123.5]
																 loopMarkers:[[AHALoopMarkers alloc] initWithStartMicroseconds:12 endMicroseconds:45]
															   timeSignature:[[AHATimeSignature alloc] initWithUpper:4 lower:8]
															 basedOnPieceIDs:@[ [NSUUID UUID] ]];

	XCTAssertEqualObjects(piece.defaultTitle, @"piece title");
	XCTAssertEqual(piece.lengthMicroseconds, 1234);
	XCTAssertEqual(piece.tempo.fixedTempo, 123.5);
	XCTAssertEqual(piece.loopMarkers.startMicroseconds, 12);
	XCTAssertEqual(piece.loopMarkers.endMicroseconds, 45);
	XCTAssertEqual(piece.timeSignature.upper, 4);
	XCTAssertEqual(piece.timeSignature.lower, 8);
	XCTAssertEqual(piece.basedOnPieceIDs.count, 1ul);
}

@end
