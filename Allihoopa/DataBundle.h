@import Foundation;

typedef NS_ENUM(NSUInteger, AHAAudioFormat) {
	AHAAudioFormatWave,
	AHAAudioFormatOggVorbis,
};

@interface AHAAudioDataBundle : NSObject

@property (readonly) AHAAudioFormat format;
@property (readonly) NSString* _Nonnull formatAsString;
@property (readonly) NSData* _Nonnull data;

- (instancetype _Nonnull)initWithFormat:(AHAAudioFormat)format
								   data:(NSData* _Nonnull)data;

@end
