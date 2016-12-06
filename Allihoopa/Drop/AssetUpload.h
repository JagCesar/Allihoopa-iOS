#import <Foundation/Foundation.h>

#import "../Promise.h"

@class AHAConfiguration;

AHAPromise<NSURL*>* AHAUploadAssetData(AHAConfiguration* configuration, NSData* data);
