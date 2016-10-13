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

static void GetUploadURL(AHAConfiguration* configuration, void(^completion)(NSURL* url, NSError* error)) {
	AHAGraphQLQuery(configuration, kGetURLQuery, @{@"count": @1}, ^(NSDictionary *response, NSError *error) {
		NSCAssert(response != nil || error != nil, @"Either a response or an error must be provided");

		if (error) {
			completion(nil, error);
			return;
		}

		if (![response[@"uploadUrls"] isKindOfClass:[NSDictionary class]]
			|| ![response[@"uploadUrls"][@"urls"] isKindOfClass:[NSDictionary class]]) {
			completion(nil, [NSError errorWithDomain:AHAAllihoopaErrorDomain
												code:AHAErrorInternalAPIError
											userInfo:@{NSLocalizedDescriptionKey: @"Expected uploadUrls in API response"}]);
			return;
		}

		NSArray* urls = response[@"uploadUrls"][@"urls"];

		if (urls.count != 1 || ![urls[0] isKindOfClass:[NSString class]]) {
			completion(nil, [NSError errorWithDomain:AHAAllihoopaErrorDomain
												code:AHAErrorInternalAPIError
											userInfo:@{NSLocalizedDescriptionKey: @"Expected URL in API response"}]);
			return;
		}

		completion([NSURL URLWithString:urls[0]], nil);
	});
}

static void UploadData(NSURL* url, NSData* data, void(^completion)(NSError* error)) {
	NSURLSession* session = [NSURLSession sharedSession];

	NSMutableURLRequest* request = [NSMutableURLRequest requestWithURL:url];
	request.HTTPMethod = @"PUT";

	NSURLSessionUploadTask* task = [session uploadTaskWithRequest:request fromData:data completionHandler:^(__unused NSData* _Nullable uploadData, NSURLResponse * _Nullable response, NSError * _Nullable error) {
		dispatch_async(dispatch_get_main_queue(), ^{
			if (error != nil) {
				completion(error);
			}
			else {
				NSCAssert([response isKindOfClass:[NSHTTPURLResponse class]],
						  @"Response not a HTTP response");
				NSHTTPURLResponse* httpResponse = (NSHTTPURLResponse*)response;

				if (httpResponse.statusCode != 200) {
					completion([NSError errorWithDomain:AHAAllihoopaErrorDomain
												   code:AHAErrorInternalUploadError
											   userInfo:@{NSLocalizedDescriptionKey: @"Unexpected upload response"}]);
				}
				else {
					completion(nil);
				}
			}
		});
	}];
	[task resume];
}


void AHAUploadAssetData(AHAConfiguration* configuration, NSData* data, void(^completion)(NSURL* url, NSError* error)) {
	GetUploadURL(configuration, ^(NSURL *url, NSError *getURLError) {
		NSCAssert(url != nil || getURLError != nil, @"Either an URL or an error must be provided");

		if (getURLError != nil) {
			completion(nil, getURLError);
		}
		else {
			UploadData(url, data, ^(NSError *uploadDataError) {
				if (uploadDataError != nil) {
					completion(nil, uploadDataError);
				}
				else {
					completion(url, nil);
				}
			});
		}
	});
}
