#import <Foundation/Foundation.h>

@class AHAConfiguration;

void AHAUploadAssetData(AHAConfiguration* configuration, NSData* data, void(^completion)(NSURL* url, NSError* error));
