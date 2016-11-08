#import "Import.h"
#import "Piece.h"
#import "Piece+Internal.h"

#import "APICommunication.h"

static NSString* const kPieceInfoGraphQLQuery = @"\
query($uuid: String!) {\
  piece(uuid: $uuid) {\
    ...%@\
  }\
}\
";

void AHAFetchPieceInfo(AHAConfiguration* configuration,
					   NSString* uuid,
					   void(^completion)(AHAPiece* piece, NSError* error)) {
	NSCAssert(configuration != nil, @"No configuration provided");
	NSCAssert(uuid != nil, @"No piece id provided");
	NSCAssert(completion != nil, @"No completion block provided");

	NSString* query = [NSString stringWithFormat:kPieceInfoGraphQLQuery, [AHAPiece graphQLFragment]];

	AHAGraphQLQuery(configuration, query, @{@"uuid": uuid}, ^(NSDictionary *response, NSError *error) {
		if (response && response[@"piece"]) {
			AHAPiece* piece = [[AHAPiece alloc] initWithPieceNode:response[@"piece"]
													configuration:configuration
															error:&error];
			completion(piece, error);
		} else {
			completion(nil, error);
		}
	});
}
