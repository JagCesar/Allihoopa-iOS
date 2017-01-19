#import <Foundation/Foundation.h>

#ifdef AHA_ENABLE_LOGGING

#define AHALog(...) NSLog(@"[AllihoopaSDK-iOS]: %@", [NSString stringWithFormat:__VA_ARGS__])

#else

#define AHALog(...)

#endif

NSBundle* AHAGetResourceBundle(void);
