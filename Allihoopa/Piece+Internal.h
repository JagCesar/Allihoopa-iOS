#import "Piece.h"

@class AHAConfiguration;

@interface AHAPiece (Internal)

+ (NSString*)graphQLFragment;

- (instancetype)initWithPieceNode:(NSDictionary*)pieceNode
					configuration:(AHAConfiguration*)configuration
							error:(NSError**)outError;

@end
