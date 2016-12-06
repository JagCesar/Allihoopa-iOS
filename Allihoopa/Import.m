#import "Import.h"
#import "Piece.h"
#import "Piece+Internal.h"
#import "Errors.h"

#import "APICommunication.h"

static NSString* const kPieceInfoGraphQLQuery = @"\
query($uuid: String!) {\
  piece(uuid: $uuid) {\
    ...%@\
  }\
}\
";

AHAPromise<AHAPiece*>* AHAFetchPieceInfo(AHAConfiguration* configuration,
										 NSString* uuid) {
	NSCAssert(configuration != nil, @"No configuration provided");
	NSCAssert(uuid != nil, @"No piece id provided");

	NSString* query = [NSString stringWithFormat:kPieceInfoGraphQLQuery, [AHAPiece graphQLFragment]];

	return [AHAGraphQLQuery(configuration, query, @{@"uuid": uuid}) map:^AHAPromise *(NSDictionary *value) {
		if (value && value[@"piece"] && (id)value[@"piece"] != [NSNull null]) {
			NSError* error;
			AHAPiece* piece = [[AHAPiece alloc] initWithPieceNode:value[@"piece"]
													configuration:configuration
															error:&error];

			if (error) {
				return [[AHAPromise alloc] initWithError:error];
			}

			return [[AHAPromise alloc] initWithValue:piece];
		} else {
			return [[AHAPromise alloc] initWithError:
					[NSError errorWithDomain:AHAAllihoopaErrorDomain code:AHAErrorInternalAPIError userInfo:@{}]];
		}
	}];
}
