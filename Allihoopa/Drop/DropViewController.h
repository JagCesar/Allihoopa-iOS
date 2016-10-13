@import UIKit;

@protocol AHADropDelegate;
@class AHADropPieceData;
@class AHAConfiguration;

@interface AHADropViewController : UINavigationController

@property (readwrite, nonatomic) AHAConfiguration* configuration;
@property (readwrite, nonatomic) id<AHADropDelegate> dropDelegate;
@property (readwrite, nonatomic) AHADropPieceData* dropPieceData;
@property (readwrite, nonatomic) BOOL dismissWhenCloseTapped;

@end