#import "DataBundle.h"
#import "Errors.h"

@implementation AHAAudioDataBundle {
	AHAAudioFormat _format;
	NSData* _data;
}

- (AHAAudioFormat)format { return _format; }
- (NSData *)data { return _data; }

- (instancetype)initWithFormat:(AHAAudioFormat)format data:(NSData *)data {
	if ((self = [super init])) {
		if (!data) {
			AHARaiseInvalidUsageException(@"Data must not be nil");
		}

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

	AHARaiseInvalidUsageException(@"Unknown audio format");
}

@end
