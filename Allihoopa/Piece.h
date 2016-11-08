@import UIKit;

#import "DataBundle.h"

@class AHAPieceID;
@class AHAFixedTempo;
@class AHALoopMarkers;
@class AHATimeSignature;

@interface AHAPiece : NSObject

@property (readonly) AHAPieceID* _Nonnull pieceID;
@property (readonly) NSString* _Nonnull title;
@property (readonly) NSString* _Nonnull pieceDescription;
@property (readonly) NSDate* _Nonnull createdAt;
@property (readonly) NSURL* _Nonnull url;

@property (readonly) NSString* _Nonnull authorUsername;

@property (readonly) NSInteger lengthMicroseconds;

@property (readonly) AHAFixedTempo* _Nullable tempo;
@property (readonly) AHALoopMarkers* _Nullable loop;
@property (readonly) AHATimeSignature* _Nullable timeSignature;

- (void)downloadMixStemWithFormat:(AHAAudioFormat)format
					   completion:(void(^ _Nonnull)(NSData* _Nullable, NSError* _Nullable))completion
NS_SWIFT_NAME(downloadMixStem(format:completion:));

- (void)downloadAudioPreviewWithFormat:(AHAAudioFormat)format
							completion:(void(^ _Nonnull)(NSData* _Nullable, NSError* _Nullable))completion
NS_SWIFT_NAME(downloadAudioPreview(format:completion:));

- (void)downloadCoverImage:(void(^ _Nonnull)(UIImage* _Nullable, NSError* _Nullable))completion
NS_SWIFT_NAME(downloadCoverImage(completion:));

@end
