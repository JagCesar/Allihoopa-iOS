#import <Foundation/Foundation.h>

@class UIImage;
@class ACAccount;
@class ACAccountCredential;

@class AHAConfiguration;
@class AHADropPieceData;
@class AHADropInfo;

@protocol AHADropDelegate;


@protocol AHADropCoordinatorDelegate <NSObject>
@required

- (void)defaultCoverImageDidArrive:(UIImage*)image;
- (void)socialQuickPostingFailedForNetwork:(NSString*)networkName;
- (void)didCreatePiece:(NSDictionary*)createdPiece;
- (void)didDownloadFinalCoverImage:(UIImage*)image;

- (void)segueToProgressViewController;
- (void)segueToErrorViewController;
- (void)segueToDropDoneViewController;

@end



@interface AHADropCoordinator : NSObject

- (instancetype)initWithConfiguration:(AHAConfiguration*)configuration
				  coordinatorDelegate:(id<AHADropCoordinatorDelegate>)coordinatorDelegate
						 dropDelegate:(id<AHADropDelegate>)dropDelegate
							pieceData:(AHADropPieceData*)dropPieceData;

- (void)runDropFlow;

- (void)commitPieceInfo:(AHADropInfo*)dropInfo;

@end




@interface AHADropInfo : NSObject

@property (nonatomic, readonly) NSString* title;
@property (nonatomic, readonly) NSString* pieceDescription;
@property (nonatomic, readonly) BOOL isListed;
@property (nonatomic, readonly) UIImage* coverImage;
@property (nonatomic, readonly) ACAccount* facebookAccount;
@property (nonatomic, readonly) ACAccountCredential* facebookAccountCredential;
@property (nonatomic, readonly) ACAccount* twitterAccount;

- (instancetype)initWithTitle:(NSString*)title
			 pieceDescription:(NSString*)pieceDescription
					   listed:(BOOL)isListed
				   coverImage:(UIImage*)coverImage
			  facebookAccount:(ACAccount*)facebookAccount
	facebookAccountCredential:(ACAccountCredential*)facebookAccountCredential
			   twitterAccount:(ACAccount*)twitterAccount;

@end

