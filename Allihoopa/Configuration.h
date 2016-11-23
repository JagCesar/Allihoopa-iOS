#import <Foundation/Foundation.h>

/**
 Storage for both persistent and transient application/user data.
 
 The application identifier and API key are transient - they are not stored on
 disk. Any modifications made by the -update method will be persisted to disk.
 */
@interface AHAConfiguration : NSObject

@property (readonly) NSString* _Nonnull applicationIdentifier;
@property (readonly) NSString* _Nonnull apiKey;

@property (readonly) NSDictionary<NSString*,id>* _Nonnull configuration;

@property (nonatomic) NSString* _Nullable accessToken;

- (void)setupApplicationIdentifier:(NSString* _Nonnull)applicationIdentifier
							apiKey:(NSString* _Nonnull)apiKey;

/**
 Execute multiple updates to the persisted configuration atomically
 
 If the block throws an exception, the modifications will not be persisted and
 the exception will be passed on to the caller.
 */
- (void)update:(void (^ _Nonnull)(NSMutableDictionary<NSString*,id>* _Nonnull configuration))updateBlock;

@end
