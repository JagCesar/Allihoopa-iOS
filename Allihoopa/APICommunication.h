#import <Foundation/Foundation.h>

#import "Promise.h"

@class AHAConfiguration;

AHAPromise<NSDictionary*>* AHAGraphQLQuery(AHAConfiguration* configuration,
										   NSString* query,
										   NSDictionary* variables);


AHAPromise<NSDictionary*>* AHARetryingGraphQLQuery(AHAConfiguration* configuration,
												   NSString* query,
												   NSDictionary* variables,
												   NSTimeInterval delay,
												   NSInteger maxAttempts,
												   BOOL(^isSuccessfulPredicate)(NSDictionary* response));
