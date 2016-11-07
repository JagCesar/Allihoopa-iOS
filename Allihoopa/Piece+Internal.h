#import "Piece.h"

@interface AHAPiece (Internal)

+ (NSString*)graphQLFragment;

- (instancetype)initWithPieceNode:(NSDictionary*)pieceNode error:(NSError**)outError;

@end
