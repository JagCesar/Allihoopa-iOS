@import Foundation;

@class AHAPiece;
@class AHAConfiguration;

void AHAFetchPieceInfo(AHAConfiguration* configuration,
					   NSString* uuid,
					   void(^completion)(AHAPiece* piece, NSError* error));