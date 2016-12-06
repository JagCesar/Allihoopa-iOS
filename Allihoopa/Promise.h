#import <Foundation/Foundation.h>


/**
 Simple Promise implementation for Objective-C
 
 A promise represents a value that might not yet be available - e.g. through an asynchronous
 network request or another promise that is not available either. It might be either resolved
 to a value, or rejected with an error.
 
 AHAPromise puts no restriction on what values or errors you provide: values can be of any type
 and both values and errors might be nil.
 
 All attached listener blocks, no matter how they were registered, will be called on the main queue
 asynchronously after the promise was rejected or resolved. Listener blocks attached _after_ a
 promise has been resolved or rejected will still be called, they too asynchronously on the
 main queue.
 */
@interface AHAPromise<T> : NSObject

/// Create a promise from a block. Either call the resolve or reject function depending on
/// the result of the computation.
- (instancetype)initWithResolver:(void(^)( void(^resolve)(T success), void(^reject)(NSError* error) ))resolver;

/// Create a resolved promise from a given value
- (instancetype)initWithValue:(T)value;

/// Create a rejected promise from a given error
- (instancetype)initWithError:(NSError*)error;

/// Create a promise that vill resolve itself when all of the provided promises have been
/// resolved. The result value will be an array with all results in the order they appear
/// in the argument to this function.
///
/// Any nil values will be replaced with NSNull instances.
///
/// If any of the promises are rejected, this promise will immediately be rejected.
- (instancetype)initWithPromises:(NSArray<AHAPromise*>*)promises;

/// Resolve a promise to a successful value. May only be called once per instance.
///
/// Also, can not be called after `rejectWithError` has been called.
- (void)resolveWithValue:(T)value;

/// Reject a promise to with an error. May only be called once per instance.
///
/// Also, can not be called after `resolveWithValue` has been called.
- (void)rejectWithError:(NSError*)error;

/// Return a new promise by mapping a resolved value to a new promise. Rejections will be
/// passed to the returned promise unmapped.
///
/// Returning nil from the block is supported and can be used to stop the execution
/// of an entire promise chain when e.g. an owning object is deallocated.
- (AHAPromise*)map:(AHAPromise* (^)(T value))mapper;

/// Return a new promise by mapping a resolved value to a new value. Similar to `map` but
/// suitable for operations that can't fail.
- (AHAPromise*)mapValue:(id (^)(T value))mapper;

/// Return a new promise by mapping the rejected error to a new promise. Resolved values
/// will be passed to the returned promise unmapped.
- (AHAPromise*)mapError:(AHAPromise* (^)(NSError* error))mapper;

/// Map both the value and error to a new promise. The same as chaining map and mapError.
- (AHAPromise*)map:(AHAPromise* (^)(T value))valueMapper error:(AHAPromise* (^)(NSError* error))errorMapper;

/// Return a promise that rejects if the block returns false.
- (AHAPromise*)filter:(BOOL(^)(T value))block;

/// Attach generic success/failure listeners to the promise.
- (void)onSuccess:(void(^)(T value))successHandler failure:(void(^)(NSError* error))failureHandler;

/// Attach a generic failure listener.
- (void)onFailure:(void(^)(NSError* error))failureHandler;

/// Attach a combined success/failure listener. Take care to only do this on promises that
/// resolve/reject with non-null values/errors, otherwise you will not be able to distinguish
/// between a resolved or rejected state.
- (void)onComplete:(void(^)(T value, NSError* error))completion;

@end
