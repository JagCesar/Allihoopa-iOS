#import <UIKit/UIKit.h>

@interface AHAModalEditor : UIViewController

@property (readonly) NSString* text;

- (void)setTitle:(NSString*)title
	   maxLength:(NSInteger)maxLength
			text:(NSString*)text
		   style:(UIFont*)font
        notEmpty:(BOOL)notEmpty;


@end
