#import <UIKit/UIKit.h>

@protocol AHADropDelegate;
@class AHADropPieceData;
@class AHAConfiguration;

@interface AHADropViewController : UINavigationController

@property (readwrite, nonatomic) AHAConfiguration* configuration;
@property (readwrite, nonatomic) __weak id<AHADropDelegate> dropDelegate;
@property (readwrite, nonatomic) AHADropPieceData* dropPieceData;
@property (readwrite, nonatomic) BOOL dismissWhenCloseTapped;

@end
