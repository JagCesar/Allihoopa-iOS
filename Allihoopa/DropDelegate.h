@import Foundation;

#import "DropPieceData.h"
#import "DataBundle.h"

/**
 Data provider for the drop process

 Implement this protocol to let your app asynchronously provide data ta upload
 when the user wants to drop a piece.
 */
@protocol AHADropDelegate <NSObject>
@required

/**
 Render the main audio data for the piece.

 The "mix stem" is the audio to be placed on a timeline by a consuming app. Call
 the completion handler *on the main queue* when data is available. If you need
 to do time consuming work, you should dispatch that to a background queue to
 keep the interface responsive.

 You need to provide *either* an error or a data bundle, otherwise an
 `NSException` for invalid usage will be raised.

 If you provide an error, the drop process will fail and present the user with
 an error message.
 */
- (void)renderMixStemForPiece:(AHADropPieceData* _Nonnull)piece
				   completion:(void(^ _Nonnull)(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error))completion;

@optional

/**
 Optionally render the preview audio for the piece.

 The "preview audio" is the audio played to the user on the website and other
 apps. It is optional, and the mix stem will be used in its stead if omitted.

 Unlike the mix stem callback, it's *not* an error to call the completion
 handler with both nil bundle and error - in this case it's treated as this
 method not being implemented at all.

 If you provide an error, the drop process will fail and present the user with
 an error message.
 */
- (void)renderPreviewAudioForPiece:(AHADropPieceData* _Nonnull)piece
						completion:(void(^ _Nonnull)(AHAAudioDataBundle* _Nullable bundle, NSError* _Nullable error))completion;

/**
 Optionally provide a default cover image for the piece.

 If the user has uploaded an image to your application, you could send it to the
 SDK here. The image must to be 640x640 px dimensions. If you call the
 completion handler with a nil image, it is simply ignored.
 */
- (void)renderCoverImageForPiece:(AHADropPieceData* _Nonnull)piece
					  completion:(void(^ _Nonnull)(UIImage* _Nullable))completion;

/**
 Called by the drop view controller when it's dismissed by the user.
 */
- (void)dropViewControllerForPieceWillClose:(AHADropPieceData* _Nonnull)piece
						afterSuccessfulDrop:(BOOL)successfulDrop;


@end
