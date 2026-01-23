//
//  WAWiFiConfigManager.h
//  wise_apartment
//
//  Manages WiFi configuration for smart lock devices
//

#import <Foundation/Foundation.h>

@class WAEventEmitter;

NS_ASSUME_NONNULL_BEGIN

typedef void(^WAWiFiConfigCompletion)(BOOL success, NSError * _Nullable error);

@interface WAWiFiConfigManager : NSObject

- (instancetype)initWithEventEmitter:(WAEventEmitter *)eventEmitter;

/**
 * Configure WiFi credentials on a paired device
 * @param deviceId Device identifier
 * @param ssid WiFi network SSID
 * @param password WiFi password
 * @param wifiType WiFi security type (0=Open, 1=WPA2, etc.)
 * @param timeout Configuration timeout in seconds
 * @param completion Callback with result
 */
- (void)configureWifiForDevice:(NSString *)deviceId
                          ssid:(NSString *)ssid
                      password:(NSString *)password
                      wifiType:(NSInteger)wifiType
                       timeout:(NSTimeInterval)timeout
                    completion:(WAWiFiConfigCompletion)completion;

/**
 * Cancel ongoing WiFi configuration
 */
- (void)cancelConfiguration;

/**
 * Check if configuration is in progress
 */
- (BOOL)isConfiguring;

@end

NS_ASSUME_NONNULL_END
