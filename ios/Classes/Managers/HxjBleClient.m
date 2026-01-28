#import "HxjBleClient.h"

#import "../../Frameworks/HXJBLESDK.framework/Headers/HXBluetoothLockHelper.h"

@interface HxjBleClient ()
@property (nonatomic, strong) NSMutableDictionary<NSString *, NSDictionary *> *authCache;
@end

@implementation HxjBleClient

- (instancetype)init {
    self = [super init];
    if (self) {
        _authCache = [NSMutableDictionary dictionary];
    }
    return self;
}

- (void)setAuth:(NSDictionary *)auth forMac:(NSString *)mac {
    if (![auth isKindOfClass:[NSDictionary class]]) return;
    if (![mac isKindOfClass:[NSString class]] || mac.length == 0) return;
    NSString *key = [mac lowercaseString];
    @synchronized (self) {
        self.authCache[key] = [NSDictionary dictionaryWithDictionary:auth];
    }
}

- (NSDictionary *)authForMac:(NSString *)mac {
    if (![mac isKindOfClass:[NSString class]] || mac.length == 0) return nil;
    NSString *key = [mac lowercaseString];
    @synchronized (self) {
        return self.authCache[key];
    }
}

- (void)clearAuthForMac:(NSString *)mac {
    if (![mac isKindOfClass:[NSString class]] || mac.length == 0) return;
    NSString *key = [mac lowercaseString];
    @synchronized (self) {
        [self.authCache removeObjectForKey:key];
    }
}

- (void)disConnectBle:(void (^)(void))callback {
    NSString *mac = self.lastConnectedMac;
    if (mac.length > 0) {
        [HXBluetoothLockHelper tryDisconnectPeripheralWithMac:mac];
    }
    if (callback) {
        dispatch_async(dispatch_get_main_queue(), callback);
    }
}

@end
