#import <Foundation/Foundation.h>

//! Name of the `NSException` that is raised when the SDK is incorrectly used
extern NSString* const AHAInvalidUsageException;

//! General domain for `NSError`s produced by this SDK
extern NSString* const AHAAllihoopaErrorDomain;

typedef NS_ENUM(NSInteger, AHAError) {
	AHAErrorPieceTempoTooHigh = 1001,
	AHAErrorPieceTempoTooLow = 1002,
	AHAErrorPieceInvalidLoopMarkers = 1003,
	AHAErrorPieceInvalidTimeSignature = 1004,
	AHAErrorPieceTooShort = 1005,
	AHAErrorPieceTooLong = 1006,
	AHAErrorPieceTitleTooShort = 1007,
	AHAErrorPieceTitleTooLong = 1008,

	AHAErrorInternalAPIError = 2001,
	AHAErrorInternalUploadError = 2002,
	AHAErrorInternalDownloadError = 2003,
	AHAErrorInternalMaxRetriesReached = 2004,

	AHAErrorImportPieceNotFound = 3001,
};


void AHARaiseInvalidUsageException(NSString* format, ...) __attribute__((noreturn));
