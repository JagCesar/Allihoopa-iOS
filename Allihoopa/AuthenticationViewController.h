@import UIKit;

typedef void (^AHAAuthenticationControllerCallback)(BOOL successful);

@class AHAConfiguration;

@interface AHAAuthenticationViewController : UIViewController

- (instancetype)initWithConfiguration:(AHAConfiguration*)configuration
					completionHandler:(AHAAuthenticationControllerCallback)completionHandler;

- (BOOL)handleOpenURL:(NSURL*)url;

@end
