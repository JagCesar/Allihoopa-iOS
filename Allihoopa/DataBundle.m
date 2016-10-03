#import "DataBundle.h"

@implementation AHAAudioDataBundle {
	AHAAudioFormat _format;
	NSData* _data;
}

- (AHAAudioFormat)format { return _format; }
- (NSData *)data { return _data; }

- (instancetype)initWithFormat:(AHAAudioFormat)format data:(NSData *)data {
	if ((self = [super init])) {
		NSAssert(data != nil, @"data must not be nil");

		_format = format;
		_data = data;
	}

	return self;
}

- (NSString *)formatAsString {
	switch (_format) {
		case AHAAudioFormatWave: return @"wav";
		case AHAAudioFormatOggVorbis: return @"ogg";
	}

	NSAssert(false, @"Unknown audio format");
}

@end
