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

	CGRect upperRightFrame = CGRectMake(0.27f * width, 0, 0.73f * width, 0.73f * height);
	CGRect lowerLeftFrame = CGRectMake(0, 0.27f * height, 0.73f * width, 0.73f * height);

	CGFloat xOffset = 0;
	CGFloat yOffset = 0;

	if (t < 0.25) {
		yOffset = (CGFloat)t * 4;
	}
	else if (t < 0.5) {
		xOffset = ((CGFloat)t - 0.25f) * 4;
		yOffset = 1;
	}
	else if (t < 0.75) {
		yOffset = (0.75f - (CGFloat)t) * 4;
		xOffset = 1;
	}
	else {
		xOffset = (1 - (CGFloat)t) * 4;
	}

	xOffset = EaseInOutCubic(xOffset);
	yOffset = EaseInOutCubic(yOffset);

	upperRightFrame = CGRectOffset(upperRightFrame, -0.27f * width * xOffset, 0.27f * height * yOffset);
	lowerLeftFrame = CGRectOffset(lowerLeftFrame, 0.27f * width * xOffset, -0.27f * height * yOffset);

	[[UIColor colorWithRed:1.0 green:0.15234375f blue:1.0 alpha:1.0] setFill];
	[[UIBezierPath bezierPathWithOvalInRect:upperRightFrame] fillWithBlendMode:kCGBlendModeMultiply alpha:1.0];

	[[UIColor colorWithRed:0.16f green:0.86f blue:0.16f alpha:1.0] setFill];
	[[UIBezierPath bezierPathWithOvalInRect:lowerLeftFrame] fillWithBlendMode:kCGBlendModeMultiply alpha:1.0];
}

@end
