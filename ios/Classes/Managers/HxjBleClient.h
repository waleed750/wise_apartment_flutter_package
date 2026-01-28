#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface HxjBleClient : NSObject

@property (nonatomic, copy, nullable) NSString *lastConnectedMac;

// Cache per-lock auth material learned during addDevice (or provided once).
// Keyed by lowercase mac.
- (void)setAuth:(NSDictionary *)auth forMac:(NSString *)mac;
- (NSDictionary * _Nullable)authForMac:(NSString *)mac;
- (void)clearAuthForMac:(NSString *)mac;

- (void)disConnectBle:(nullable void (^)(void))callback;

@end

NS_ASSUME_NONNULL_END
