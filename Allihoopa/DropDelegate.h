@import Foundation;

#import "DropPieceData.h"
#import "DataBundle.h"

@protocol AHADropDelegate <NSObject>
@required

- (void)renderMixStemForPiece:(AHADropPieceData* _Nonnull)piece
				   completion:(void(^ _Nonnull)(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error))completion;

@optional

- (void)renderPreviewAudioForPiece:(AHADropPieceData* _Nonnull)piece
						completion:(void(^ _Nonnull)(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error))completion;
- (void)renderCoverImageForPiece:(AHADropPieceData* _Nonnull)piece
					  completion:(void(^ _Nonnull)(UIImage* _Nullable))completion;

- (void)dropViewControllerForPieceWillClose:(AHADropPieceData* _Nonnull)piece
						afterSuccessfulDrop:(BOOL)successfulDrop;


@end
