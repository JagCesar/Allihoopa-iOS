@import Foundation;

@class AHAConfiguration;

void AHAUploadAssetData(AHAConfiguration* configuration, NSData* data, void(^completion)(NSURL* url, NSError* error));
