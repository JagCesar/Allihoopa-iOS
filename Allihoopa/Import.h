#import <Foundation/Foundation.h>

#import "Promise.h"

@class AHAPiece;
@class AHAConfiguration;

AHAPromise<AHAPiece*>* AHAFetchPieceInfo(AHAConfiguration* configuration,
										 NSString* uuid);
