#import "AllihoopaInstallerViewController.h"
#import <StoreKit/StoreKit.h>

@interface AllihoopaInstallerColors : NSObject
+ (UIColor *)unripeAvocadoGreen;
+ (UIColor *)birkenstockGray;
+ (UIColor *)adamantiumGray;
+ (UIColor *)smokehouseGray;
+ (UIColor *)puppyNosePink;
@end

@implementation AllihoopaInstallerColors

+ (UIColor *)unripeAvocadoGreen {
    return [UIColor colorWithRed:37.0/255.0 green:201.0/255.0 blue:37.0/255.0 alpha:1.0];
}

+ (UIColor *)birkenstockGray {
    return [UIColor colorWithWhite:74.0/255.0 alpha:1.0];
}

+ (UIColor *)adamantiumGray {
    return [UIColor colorWithWhite:155.0/255.0 alpha:1.0];
}

+ (UIColor *)smokehouseGray {
    return [UIColor colorWithWhite:195.0/255.0 alpha:1.0];
}

+ (UIColor *)puppyNosePink {
    return [UIColor colorWithRed:1.0 green:39/255.0 blue:1.0 alpha:1.0];
}

@end

@interface ListElementView: UIView
@property (strong, nonatomic) IBOutlet UIImageView *iconImageView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;

- (void)setColors;
@end

@implementation ListElementView: UIView

- (void)setColors {
    [_iconImageView setTintColor:[AllihoopaInstallerColors smokehouseGray]];
    [_titleLabel setTextColor:[AllihoopaInstallerColors birkenstockGray]];
}

@end

@interface AllihoopaInstallerViewController () <SKStoreProductViewControllerDelegate>

@property (copy, nonatomic) NSString *pieceIdentifier;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *closeTopConstraint;
@property (strong, nonatomic) IBOutlet NSLayoutConstraint *closeLeftConstraint;
@property (strong, nonatomic) IBOutlet UIButton *closeButton;
@property (strong, nonatomic) IBOutlet UIScrollView* scrollView;
@property (strong, nonatomic) IBOutlet UILabel *titleLabel;
@property (strong, nonatomic) IBOutlet UILabel *bodyLabel;
@property (strong, nonatomic) IBOutlet UILabel *subtitleLabel;
@property (strong, nonatomic) IBOutletCollection(ListElementView) NSArray *listElements;
@property (strong, nonatomic) IBOutlet UIImageView *shadowImageView;
@property (strong, nonatomic) IBOutlet UIButton *installButton;
@property (strong, nonatomic) IBOutlet UIButton *viewInBrowserButton;

@end

@implementation AllihoopaInstallerViewController

- (instancetype)initWithPieceIdentifier:(NSString *)pieceIdentifier nibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if (self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil]) {
        [self setPieceIdentifier:pieceIdentifier];
    }
    return self;
}

- (void)dealloc {
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(applicationDidEnterBackground) name:UIApplicationDidEnterBackgroundNotification object:nil];
    [self setColors];
}

- (void)viewDidLayoutSubviews {
    [super viewDidLayoutSubviews];
    [[self scrollView] setScrollEnabled:[self isScrollViewContentSizeHigherThanScrollViewFrame]];
    [[self shadowImageView] setHidden:![self isScrollViewContentSizeHigherThanScrollViewFrame]];

	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad) {
		[_closeLeftConstraint setConstant:20];
		[_closeTopConstraint setConstant:8];
	}
}

- (BOOL)isScrollViewContentSizeHigherThanScrollViewFrame {
    return [[self scrollView] contentSize].height > [[self scrollView] frame].size.height;
}

- (void)setColors {
    [_closeButton setTintColor:[AllihoopaInstallerColors unripeAvocadoGreen]];
    [_titleLabel setTextColor:[AllihoopaInstallerColors birkenstockGray]];
    [_bodyLabel setTextColor:[AllihoopaInstallerColors adamantiumGray]];
    [_subtitleLabel setTextColor:[AllihoopaInstallerColors birkenstockGray]];
    for (ListElementView *view in _listElements) {
        [view setColors];
    }
    [_installButton setTintColor:[UIColor whiteColor]];
    [_installButton setBackgroundColor:[AllihoopaInstallerColors puppyNosePink]];
    [_viewInBrowserButton setTintColor:[AllihoopaInstallerColors adamantiumGray]];
}

- (void)applicationDidEnterBackground {
    [self dismiss];
}

- (IBAction)dismiss {
    if ([self presentedViewController]) {
        [[self presentedViewController] dismissViewControllerAnimated:YES completion:nil];
    }
    [self dismissViewControllerAnimated:YES completion:nil];
}

- (IBAction)openAllihoopaInAppStore {
    SKStoreProductViewController *storeProductViewController = [[SKStoreProductViewController alloc] init];
    [storeProductViewController setDelegate:self];
    [storeProductViewController loadProductWithParameters:@{SKStoreProductParameterITunesItemIdentifier: @1205869465} completionBlock:nil];
    [self presentViewController:storeProductViewController animated:YES completion:nil];
}

- (IBAction)openPieceInBrowser {
    NSURL *pieceURL = [NSURL URLWithString:[NSString stringWithFormat:@"https://allihoopa.com/s/%@", _pieceIdentifier]];
    [[UIApplication sharedApplication] openURL:pieceURL];
}

// MARK: - SKStoreProductViewControllerDelegate

- (void)productViewControllerDidFinish:(SKStoreProductViewController *)viewController {
    [viewController dismissViewControllerAnimated:YES completion:nil];
}

@end
