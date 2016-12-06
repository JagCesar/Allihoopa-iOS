#import "APICommunication.h"

#import "Allihoopa+Internal.h"

#import "Configuration.h"
#import "Errors.h"

static NSURLSession* CreateURLSession(AHAConfiguration* configuration) {
	NSMutableDictionary* headers = [NSMutableDictionary new];
	headers[@"Allihoopa-API-Key"] = configuration.apiKey;

	if (configuration.accessToken) {
		headers[@"PH-Access-Token"] = configuration.accessToken;
	}

	NSURLSessionConfiguration* sessionConfig = [NSURLSessionConfiguration defaultSessionConfiguration];
	sessionConfig.HTTPAdditionalHeaders = headers;

	return [NSURLSession sessionWithConfiguration:sessionConfig];
}

AHAPromise<NSDictionary*>* AHAGraphQLQuery(AHAConfiguration* configuration,
										  NSString* query,
										  NSDictionary* variables) {
	NSCAssert(configuration != nil, @"No configuration provided");
	NSCAssert(query != nil, @"No query provided");
	NSCAssert(variables != nil, @"No variables provided");

	NSError* outError;
	NSData* postBody = [NSJSONSerialization dataWithJSONObject:@{@"query": query, @"variables": variables}
													   options:(NSJSONWritingOptions)0
														 error:&outError];
	NSCAssert(postBody != nil && outError == nil, @"Could not serialize JSON data");

	AHALog(@"Sending GraphQL query %@, variables %@", query, variables);

	NSURLSession* session = CreateURLSession(configuration);
	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:[NSURL URLWithString:GRAPHQL_URL]];
	request.HTTPMethod = @"POST";
	request.HTTPBody = postBody;
	[request setValue:@"application/json" forHTTPHeaderField:@"Content-Type"];

	AHAPromise<NSDictionary*>* promise = [[AHAPromise<NSDictionary*> alloc] initWithResolver:^(void (^resolve)(id success), void (^reject)(NSError *error)) {
		NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
			NSCAssert(data != nil || error != nil, @"Either data or error must be provided");

			if (error != nil) {
				reject(error);
			}
			else {
				NSError* parseError;
				NSDictionary* result = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&parseError];
				NSCAssert(parseError != nil || result != nil, @"No data or error was provided");
				NSCAssert([response isKindOfClass:[NSHTTPURLResponse class]],
						  @"URL response not an HTTP response");

				NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

				if (parseError) {
					reject(error);
				}
				else if (httpResponse.statusCode != 200) {
					AHALog(@"GraphQL parsed error response: %@", result);
					reject([NSError errorWithDomain:AHAAllihoopaErrorDomain
											   code:AHAErrorInternalAPIError
										   userInfo:@{NSLocalizedDescriptionKey: @"GraphQL returned error"}]);
				}
				else if (![result isKindOfClass:[NSDictionary class]] || !result[@"data"]) {
					AHALog(@"GraphQL parsed error response: %@", result);
					reject([NSError errorWithDomain:AHAAllihoopaErrorDomain
											   code:AHAErrorInternalAPIError
										   userInfo:@{NSLocalizedDescriptionKey: @"GraphQL returned invalid JSON response"}]);
				}
				else {
					resolve(result[@"data"]);
				}
			}
		}];

		[task resume];
	}];

	return promise;
}

AHAPromise<NSDictionary*>* AHARetryingGraphQLQuery(AHAConfiguration* configuration,
												   NSString* query,
												   NSDictionary* variables,
												   NSTimeInterval delay,
												   NSInteger maxAttempts,
												   BOOL(^isSuccessfulPredicate)(NSDictionary* response)) {
	NSCAssert(configuration != nil, @"No configuration provided");
	NSCAssert(query != nil, @"No query provided");
	NSCAssert(variables != nil, @"No variables provided");
	NSCAssert(delay >= 0, @"Delay must be positive");
	NSCAssert(maxAttempts >= 0, @"Max attempts must be positive");
	NSCAssert(isSuccessfulPredicate != nil, @"No successful attempt predicate provided");

	if (maxAttempts == 0) {
		return [[AHAPromise alloc] initWithError:
				[NSError errorWithDomain:AHAAllihoopaErrorDomain
									code:AHAErrorInternalMaxRetriesReached
								userInfo:@{ NSLocalizedDescriptionKey: @"Max number of retries reached when attempting to fetch data"}]];
	}

	return [[AHAGraphQLQuery(configuration, query, variables)
			filter:^BOOL(NSDictionary *value) {
				return isSuccessfulPredicate(value);
			}]
			mapError:^AHAPromise *(__unused NSError* originalError) {
				return [[AHAPromise alloc] initWithResolver:^(void (^resolve)(id success), void (^reject)(NSError *error)) {
					dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(delay * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
						AHALog(@"Retrying query");
						[AHARetryingGraphQLQuery(configuration,
												query,
												variables,
												delay,
												maxAttempts - 1,
												isSuccessfulPredicate)
						 onSuccess:^(NSDictionary *value) {
							 resolve(value);
						 } failure:^(NSError *error) {
							 reject(error);
						 }];
					});
				}];
			}];
}
