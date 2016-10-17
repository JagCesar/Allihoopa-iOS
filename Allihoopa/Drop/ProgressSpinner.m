#import "ProgressSpinner.h"

#import "../Allihoopa+Internal.h"

static CGFloat EaseInOutCubic(CGFloat t) {
	t *= 2;

	if (t < 1) {
		return t * t * t / 2;
	}

	t -= 2;
	return (t * t * t + 2)/2;
};

@implementation AHAProgressSpinner {
	CADisplayLink* _link;
	CFTimeInterval _startTime;
}

- (void)awakeFromNib {
	[super awakeFromNib];

	_link = [CADisplayLink displayLinkWithTarget:self selector:@selector(displayLinkWillRedraw:)];
	[_link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];

	_startTime = CACurrentMediaTime();
}

- (void)dealloc {
	[_link invalidate];
	_link = nil;
}

- (void)displayLinkWillRedraw:(__unused CADisplayLink*)link {
	[self setNeedsDisplay];
}

- (void)drawRect:(CGRect)rect {
	[[UIColor whiteColor] setFill];
	[[UIBezierPath bezierPathWithRect:rect] fill];

	CGRect bounds = self.bounds;
	CGFloat width = bounds.size.width;
	CGFloat height = bounds.size.height;

	double duration = 1.5;
	double t = fmod(CACurrentMediaTime() - _startTime, duration) / duration;

	CGRect upperRightFrame = CGRectMake(0.27 * width, 0, 0.73 * width, 0.73 * height);
	CGRect lowerLeftFrame = CGRectMake(0, 0.27 * height, 0.73 * width, 0.73 * height);

	CGFloat xOffset = 0;
	CGFloat yOffset = 0;

	if (t < 0.25) {
		yOffset = t * 4;
	}
	else if (t < 0.5) {
		xOffset = (t - 0.25) * 4;
		yOffset = 1;
	}
	else if (t < 0.75) {
		yOffset = (0.75 - t) * 4;
		xOffset = 1;
	}
	else {
		xOffset = (1 - t) * 4;
	}

	xOffset = EaseInOutCubic(xOffset);
	yOffset = EaseInOutCubic(yOffset);

	upperRightFrame = CGRectOffset(upperRightFrame, -0.27 * width * xOffset, 0.27 * height * yOffset);
	lowerLeftFrame = CGRectOffset(lowerLeftFrame, 0.27 * width * xOffset, -0.27 * height * yOffset);

	[[UIColor colorWithRed:1.0 green:0.15234375f blue:1.0 alpha:1.0] setFill];
	[[UIBezierPath bezierPathWithOvalInRect:upperRightFrame] fillWithBlendMode:kCGBlendModeMultiply alpha:1.0];

	[[UIColor colorWithRed:0.16 green:0.86 blue:0.16 alpha:1.0] setFill];
	[[UIBezierPath bezierPathWithOvalInRect:lowerLeftFrame] fillWithBlendMode:kCGBlendModeMultiply alpha:1.0];
}

@end
