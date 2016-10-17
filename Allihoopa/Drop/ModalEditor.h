@import UIKit;

@interface AHAModalEditor : UIViewController

@property (readonly) NSString* text;

- (void)setTitle:(NSString*)title
	   maxLength:(NSInteger)maxLength
			text:(NSString*)text;


@end
