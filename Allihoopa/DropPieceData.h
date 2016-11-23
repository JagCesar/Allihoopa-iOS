#import <Foundation/Foundation.h>

@interface AHAPieceID : NSObject

@property (readonly) NSString* _Nonnull pieceID;

- (instancetype _Nonnull)initWithPieceID:(NSString* _Nonnull)pieceID;

@end

@interface AHAFixedTempo : NSObject

@property (readonly) double fixedTempo;

- (instancetype _Nonnull)initWithFixedTempo:(double)fixedTempo;

@end

@interface AHALoopMarkers : NSObject

@property (readonly) NSInteger startMicroseconds;
@property (readonly) NSInteger endMicroseconds;

- (instancetype _Nonnull)initWithStartMicroseconds:(NSInteger)startMicroseconds
								   endMicroseconds:(NSInteger)endMicroseconds;

@end

@interface AHATimeSignature : NSObject

@property (readonly) NSInteger upper;
@property (readonly) NSInteger lower;

- (instancetype _Nonnull)initWithUpper:(NSInteger)upper
								 lower:(NSInteger)lower;

@end

@interface AHADropPieceData : NSObject

// Presentation data
@property (readonly) NSString* _Nonnull defaultTitle;

// Musical metadata
@property (readonly) NSInteger lengthMicroseconds;
@property (readonly) AHAFixedTempo* _Nullable tempo;
@property (readonly) AHALoopMarkers* _Nullable loopMarkers;
@property (readonly) AHATimeSignature* _Nullable timeSignature;

// Attribution data
@property (readonly) NSArray<AHAPieceID*>* _Nonnull basedOnPieceIDs;

- (instancetype _Nonnull)init NS_UNAVAILABLE;

- (instancetype _Nullable)initWithDefaultTitle:(NSString* _Nonnull)defaultTitle
							lengthMicroseconds:(NSInteger)lengthMicroseconds
										 tempo:(AHAFixedTempo* _Nullable)tempo
								   loopMarkers:(AHALoopMarkers* _Nullable)loopMarkers
								 timeSignature:(AHATimeSignature* _Nullable)timeSignature
							   basedOnPieceIDs:(NSArray<AHAPieceID*>* _Nonnull)basedOnPieceIDs
										 error:(NSError* _Nullable * _Nonnull)outValidationError NS_DESIGNATED_INITIALIZER;

@end
