@import Foundation;

@class AHAConfiguration;

void AHAGraphQLQuery(AHAConfiguration* configuration,
					 NSString* query,
					 NSDictionary* variables,
					 void(^completion)(NSDictionary* response, NSError* error));
