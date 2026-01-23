//
//  WAPairManager.h
//  wise_apartment
//
//  Manages device pairing/adding operations
//

#import <Foundation/Foundation.h>

@class WAEventEmitter;

NS_ASSUME_NONNULL_BEGIN

typedef void(^WAPairCompletion)(BOOL success, NSDictionary * _Nullable deviceInfo, NSError * _Nullable error);

@interface WAPairManager : NSObject

- (instancetype)initWithEventEmitter:(WAEventEmitter *)eventEmitter;

/**
 * Pair/add a device
 * @param deviceId Device identifier (MAC or UUID)
 * @param authToken Optional authentication token
 * @param deviceName Optional custom device name
 * @param completion Callback with result
 */
- (void)pairDeviceWithId:(NSString *)deviceId
               authToken:(nullable NSString *)authToken
              deviceName:(nullable NSString *)deviceName
              completion:(WAPairCompletion)completion;

/**
 * Cancel ongoing pairing
 */
- (void)cancelPairing;

/**
 * Check if pairing is in progress
 */
- (BOOL)isPairing;

@end

NS_ASSUME_NONNULL_END
