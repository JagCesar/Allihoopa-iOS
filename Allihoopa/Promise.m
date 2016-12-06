#import "Promise.h"

typedef NS_ENUM(NSInteger, AHAPromiseState) {
	AHAPromiseStatePending,
	AHAPromiseStateResolved,
	AHAPromiseStateRejected,
};

@interface AHAPromise<T> ()

@property (nonatomic) AHAPromiseState state;
@property (strong, nonatomic) T value;
@property (strong, nonatomic) NSError* error;

@property (strong, nonatomic) NSMutableArray<void(^)(T value)>* successListeners;
@property (strong, nonatomic) NSMutableArray<void(^)(NSError* error)>* failureListeners;

@end

@implementation AHAPromise

#pragma mark - Constructors

- (instancetype)init {
	if ((self = [super init])) {
		_state = AHAPromiseStatePending;
		_successListeners = [[NSMutableArray alloc] init];
		_failureListeners = [[NSMutableArray alloc] init];
	}

	return self;
}

- (instancetype)initWithResolver:(void (^)(void (^)(id), void (^)(NSError *)))resolver {
	if ((self = [self init])) {
		resolver(
				 ^(id value) {
					 [self resolveWithValue:value];
				 },
				 ^(NSError* error) {
					 [self rejectWithError:error];
				 });
	}

	return self;
}

- (instancetype)initWithPromises:(NSArray<AHAPromise *> *)promises {
	if ((self = [self init])) {
		if (promises.count == 0) {
			[self resolveWithValue:@[]];

			return self;
		}

		__block NSMutableDictionary<NSNumber*, id>* unorderedResults = [[NSMutableDictionary alloc] init];

		for (NSUInteger i = 0; i < promises.count; ++i) {
			NSNumber* indexObj = @(i);
			AHAPromise* promise = promises[i];

			[promise onSuccess:^(id value) {
				if (!value) {
					value = [NSNull null];
				}

				[unorderedResults setObject:value forKey:indexObj];

				if (unorderedResults.count == promises.count) {
					NSMutableArray* orderedResults = [[NSMutableArray alloc] init];
					for (NSUInteger j = 0; j < promises.count; ++j) {
						[orderedResults addObject:unorderedResults[@(j)]];
					}

					[self resolveWithValue:[orderedResults copy]];
				}
			} failure:^(NSError *error) {
				unorderedResults = nil;

				@synchronized (self) {
					if (self->_state == AHAPromiseStatePending) {
						[self rejectWithError:error];
					}
				}
			}];
		}
	}

	return self;
}

- (instancetype)initWithValue:(id)value {
	if ((self = [self init])) {
		[self setState:AHAPromiseStateResolved value:value error:nil];
	}

	return self;
}

- (instancetype)initWithError:(NSError *)error {
	if ((self = [self init])) {
		[self setState:AHAPromiseStateRejected value:nil error:error];
	}

	return self;
}

#pragma mark - Public methods (resolving/rejecting)

- (void)resolveWithValue:(id)value {
	[self setState:AHAPromiseStateResolved value:value error:nil];
}

- (void)rejectWithError:(NSError*)error {
	[self setState:AHAPromiseStateRejected value:nil error:error];
}

#pragma mark - Public methods (deriving new promises)

- (AHAPromise*)map:(AHAPromise *(^)(id))mapper {
	return [[AHAPromise alloc] initWithResolver:^(void (^resolve)(id success), void (^reject)(NSError *error)) {
		[self onSuccess:^(id value) {
			AHAPromise* innerPromise = mapper(value);

			[innerPromise onSuccess:^(id innerValue) {
				resolve(innerValue);
			} failure:^(NSError *error) {
				reject(error);
			}];
		} failure:^(NSError *error) {
			reject(error);
		}];
	}];
}

- (AHAPromise*)mapValue:(id (^)(id))mapper {
	return [[AHAPromise alloc] initWithResolver:^(void (^resolve)(id success), void (^reject)(NSError *error)) {
		[self onSuccess:^(id value) {
			resolve(mapper(value));
		} failure:^(NSError *error) {
			reject(error);
		}];
	}];
}

- (AHAPromise*)mapError:(AHAPromise *(^)(NSError *))mapper {
	return [[AHAPromise alloc] initWithResolver:^(void (^resolve)(id success), void (^reject)(NSError *error)) {
		[self onSuccess:^(id value) {
			resolve(value);
		} failure:^(NSError *error) {
			[mapper(error) onSuccess:^(id value) {
				resolve(value);
			} failure:^(NSError *innerError) {
				reject(innerError);
			}];
		}];
	}];
}

- (AHAPromise*)map:(AHAPromise *(^)(id))valueMapper error:(AHAPromise *(^)(NSError *))errorMapper {
	return [[self map:valueMapper] mapError:errorMapper];
}

- (AHAPromise*)filter:(BOOL (^)(id))block {
	return [[AHAPromise alloc] initWithResolver:^(void (^resolve)(id success), void (^reject)(NSError *error)) {
		[self onSuccess:^(id value) {
			if (block(value)) {
				resolve(value);
			}
			else {
				reject(nil);
			}
		} failure:^(NSError *error) {
			reject(error);
		}];
	}];
}

#pragma mark - Public methods (completion handling)

- (void)onComplete:(void (^)(id, NSError *))completion {
	[self onSuccess:^(id value) {
		if (completion) {
			completion(value, nil);
		}
	} failure:^(NSError *error) {
		if (completion) {
			completion(nil, error);
		}
	}];
}

- (void)onFailure:(void (^)(NSError *))failureHandler {
	[self onSuccess:nil failure:failureHandler];
}

- (void)onSuccess:(void (^)(id))successHandler failure:(void (^)(NSError *))failureHandler {
	@synchronized (self) {
		switch (_state) {
			case AHAPromiseStateResolved:
				if (successHandler) {
					dispatch_async(dispatch_get_main_queue(), ^{
						successHandler(self->_value);
					});
				}
				return;
			case AHAPromiseStateRejected:
				if (failureHandler) {
					dispatch_async(dispatch_get_main_queue(), ^{
						failureHandler(self->_error);
					});
				}
				return;
			case AHAPromiseStatePending:
				if (successHandler) {
					[_successListeners addObject:successHandler];
				}
				if (failureHandler) {
					[_failureListeners addObject:failureHandler];
				}
				return;
		}

		NSAssert(NO, @"AHAPromise in inconsistent state");
	}
}

#pragma mark - Private methods (resolving)

- (void)setState:(AHAPromiseState)state value:(id)value error:(NSError*)error {
	@synchronized (self) {
		NSAssert(_state == AHAPromiseStatePending, @"Can not resolve promise in non-pending state");
		NSAssert(state != AHAPromiseStatePending, @"Can not transition promise *to* a pending state");

		_state = state;
		_value = value;
		_error = error;
	}

	dispatch_async(dispatch_get_main_queue(), ^{
		if (self->_state == AHAPromiseStateResolved) {
			for (void(^listener)(id) in self->_successListeners) {
				listener(self->_value);
			}
		}
		else if (self->_state == AHAPromiseStateRejected) {
			for (void(^listener)(id) in self->_failureListeners) {
				listener(self->_error);
			}
		}

		[self->_successListeners removeAllObjects];
		[self->_failureListeners removeAllObjects];
	});
}

@end
