#import <UIKit/UIKit.h>

@class AHADropPieceData;
@protocol AHADropDelegate;

@interface AHAActivity : UIActivity

- (instancetype)initWithPiece:(AHADropPieceData*)dropPieceData
					 delegate:(id<AHADropDelegate>)delegate;


@end
