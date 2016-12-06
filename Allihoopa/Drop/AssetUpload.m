#import "AssetUpload.h"

#import "../Configuration.h"
#import "../APICommunication.h"
#import "../Errors.h"

static NSString* const kGetURLQuery = @"\
mutation($count: Int!) {\
  uploadUrls(count: $count) {\
    urls\
  }\
}\
";

static AHAPromise<NSURL*>* GetUploadURL(AHAConfiguration* configuration) {
	return [AHAGraphQLQuery(configuration, kGetURLQuery, @{@"count": @1}) map:^(NSDictionary *response) {
		NSCAssert(response != nil, @"A response must be provided");

		if (![response[@"uploadUrls"] isKindOfClass:[NSDictionary class]]
			|| ![response[@"uploadUrls"][@"urls"] isKindOfClass:[NSArray class]]) {
			return [[AHAPromise alloc] initWithError:
					[NSError errorWithDomain:AHAAllihoopaErrorDomain
										code:AHAErrorInternalAPIError
									userInfo:@{NSLocalizedDescriptionKey: @"Expected uploadUrls in API response"}]];
		}

		NSArray* urls = response[@"uploadUrls"][@"urls"];

		if (urls.count != 1 || ![urls[0] isKindOfClass:[NSString class]]) {
			return [[AHAPromise alloc] initWithError:
					[NSError errorWithDomain:AHAAllihoopaErrorDomain
										code:AHAErrorInternalAPIError
									userInfo:@{NSLocalizedDescriptionKey: @"Expected URL in API response"}]];
		}

		return [[AHAPromise alloc] initWithValue:[NSURL URLWithString:urls[0]]];
	}];
}

static AHAPromise<id>* UploadData(NSURL* url, NSData* data) {
	return [[AHAPromise<id> alloc] initWithResolver:^(void (^resolve)(id success), void (^reject)(NSError *error)) {
		NSURLSession* session = [NSURLSession sharedSession];

		NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
		request.HTTPMethod = @"PUT";

		NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request fromData:data completionHandler:^(__unused NSData* _Nullable uploadData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
			if (error != nil) {
				reject(error);
			}
			else {
				NSCAssert([response isKindOfClass:[NSHTTPURLResponse class]],
						  @"Response not a HTTP response");
				NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

				if (httpResponse.statusCode != 200) {
					reject([NSError errorWithDomain:AHAAllihoopaErrorDomain
											   code:AHAErrorInternalUploadError
										   userInfo:@{NSLocalizedDescriptionKey: @"Unexpected upload response"}]);
				}
				else {
					resolve(nil);
				}
			}
		}];
		[task resume];
	}];
}


AHAPromise<NSURL*>* AHAUploadAssetData(AHAConfiguration* configuration, NSData* data) {
	return [GetUploadURL(configuration) map:^AHAPromise *(NSURL *url) {
		return [UploadData(url, data) mapValue:^id(__unused id value) {
			return url;
		}];
	}];
}
