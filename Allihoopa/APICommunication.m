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

void AHAGraphQLQuery(AHAConfiguration* configuration,
					 NSString* query,
					 NSDictionary* variables,
					 void(^completion)(NSDictionary* response, NSError* error)) {
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

	NSURLSessionDataTask* task = [session dataTaskWithRequest:request completionHandler:^(NSData* _Nullable data, NSURLResponse* _Nullable response, NSError* _Nullable error) {
		NSCAssert(data != nil || error != nil, @"Either data or error must be provided");

		dispatch_async(dispatch_get_main_queue(), ^{
			if (error != nil) {
				completion(nil, error);
			}
			else {
				NSError* parseError;
				NSDictionary* result = [NSJSONSerialization JSONObjectWithData:data options:(NSJSONReadingOptions)0 error:&parseError];
				NSCAssert(parseError != nil || result != nil, @"No data or error was provided");
				NSCAssert([response isKindOfClass:[NSHTTPURLResponse class]],
						  @"URL response not an HTTP response");

				NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

				if (parseError) {
					completion(nil, error);
				}
				else if (httpResponse.statusCode != 200) {
					AHALog(@"GraphQL parsed error response: %@", result);
					completion(nil, [NSError errorWithDomain:AHAAllihoopaErrorDomain
														code:AHAErrorInternalAPIError
													userInfo:@{NSLocalizedDescriptionKey: @"GraphQL returned error"}]);
				}
				else if (![result isKindOfClass:[NSDictionary class]] || !result[@"data"]) {
					AHALog(@"GraphQL parsed error response: %@", result);
					completion(nil, [NSError errorWithDomain:AHAAllihoopaErrorDomain
														code:AHAErrorInternalAPIError
													userInfo:@{NSLocalizedDescriptionKey: @"GraphQL returned invalid JSON response"}]);
				}
				else {
					completion(result[@"data"], nil);
				}
			}
		});
	}];
	[task resume];
}
