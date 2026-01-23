//
//  WABluetoothStateManager.h
//  wise_apartment
//
//  Manages Bluetooth state monitoring and permissions
//

#import <Foundation/Foundation.h>
#import <CoreBluetooth/CoreBluetooth.h>

@class WAEventEmitter;

NS_ASSUME_NONNULL_BEGIN

@interface WABluetoothStateManager : NSObject

- (instancetype)initWithEventEmitter:(WAEventEmitter *)eventEmitter;

/**
 * Check if Bluetooth is available on the device
 */
- (BOOL)isBluetoothAvailable;

/**
 * Check if Bluetooth is powered on
 */
- (BOOL)isBluetoothPoweredOn;

/**
 * Get current Bluetooth state as string (for Flutter)
 * Returns: "on", "off", "unavailable", "unauthorized", "unsupported"
 */
- (NSString *)getCurrentStateString;

@end

NS_ASSUME_NONNULL_END
