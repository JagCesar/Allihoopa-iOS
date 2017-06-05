#import <UIKit/UIKit.h>

typedef void (^AHAAuthenticationControllerCallback)(BOOL successful);

@class AHAConfiguration;

@interface AHAAuthenticationViewController : UIViewController

- (instancetype)initWithConfiguration:(AHAConfiguration*)configuration
                   authenticationType:(AHAAuthenticationType)authenticationType
					completionHandler:(AHAAuthenticationControllerCallback)completionHandler;

- (BOOL)handleOpenURL:(NSURL*)url;

@end
