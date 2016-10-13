#import "Errors.h"

NSString* const AHAInvalidUsageException = @"AHAInvalidUsageException";
NSString* const AHAAllihoopaErrorDomain = @"AHAAllihoopaErrorDomain";

void AHARaiseInvalidUsageException(NSString* format, ...) {
	va_list args;
	va_start(args, format);

	NSString* message = [[NSString alloc] initWithFormat:format arguments:args];

	@throw [NSException exceptionWithName:AHAInvalidUsageException
								   reason:message
								 userInfo:nil];
}
