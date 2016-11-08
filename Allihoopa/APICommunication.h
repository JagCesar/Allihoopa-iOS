@import Foundation;

@class AHAConfiguration;

void AHAGraphQLQuery(AHAConfiguration* configuration,
					 NSString* query,
					 NSDictionary* variables,
					 void(^completion)(NSDictionary* response, NSError* error));


void AHARetryingGraphQLQuery(AHAConfiguration* configuration,
							 NSString* query,
							 NSDictionary* variables,
							 NSTimeInterval delay,
							 NSInteger maxAttempts,
							 BOOL(^isSuccessfulPredicate)(NSDictionary* response),
							 void(^completion)(NSDictionary* response, NSError* error));
