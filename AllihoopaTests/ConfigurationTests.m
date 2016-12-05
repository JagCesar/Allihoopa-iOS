#import <XCTest/XCTest.h>

#import "../Allihoopa/Configuration.h"

@interface ConfigurationTests : XCTestCase
@end

@implementation ConfigurationTests

+ (void)setUp {
	srandom((unsigned int)time(NULL));
}

- (void)testSetup {
	AHAConfiguration* configuration = [[AHAConfiguration alloc] init];

	[configuration setupApplicationIdentifier:@"app-identifier" apiKey:@"apiKey" facebookAppID:nil];

	XCTAssertEqualObjects(configuration.applicationIdentifier, @"app-identifier");
	XCTAssertEqualObjects(configuration.apiKey, @"apiKey");
	XCTAssertNil(configuration.facebookAppID);
}

- (void)testSetupWithFacebookAppID {
	AHAConfiguration* configuration = [[AHAConfiguration alloc] init];

	[configuration setupApplicationIdentifier:@"app-identifier" apiKey:@"apiKey" facebookAppID:@"1234"];

	XCTAssertEqualObjects(configuration.applicationIdentifier, @"app-identifier");
	XCTAssertEqualObjects(configuration.apiKey, @"apiKey");
	XCTAssertEqualObjects(configuration.facebookAppID, @"1234");
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
