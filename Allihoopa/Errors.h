@import Foundation;

extern NSString* const AHAInvalidUsageException;


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
};


void AHARaiseInvalidUsageException(NSString* format, ...) __attribute__((noreturn));
