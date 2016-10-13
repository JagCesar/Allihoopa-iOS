#define WEB_BASE_URL @"https://allihoopa.com"
#define GRAPHQL_URL @"https://api.allihoopa.com/v1/graphql"


#ifdef AHA_ENABLE_LOGGING

#define AHALog(...) NSLog(@"[AllihoopaSDK]: %@", [NSString stringWithFormat:__VA_ARGS__])

#else

#define AHALog(...)

#endif
