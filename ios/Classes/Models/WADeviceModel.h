//
//  WADeviceModel.h
//  wise_apartment
//
//  Device model for consistent data representation
//

#import <Foundation/Foundation.h>

NS_ASSUME_NONNULL_BEGIN

@interface WADeviceModel : NSObject

@property (nonatomic, strong) NSString *deviceId;
@property (nonatomic, strong) NSString *name;
@property (nonatomic, strong, nullable) NSNumber *rssi;
@property (nonatomic, strong, nullable) NSString *manufacturerData;
@property (nonatomic, strong, nullable) NSDictionary *advertisementData;
@property (nonatomic, strong, nullable) NSString *deviceType;

/**
 * Convert device model to Flutter-compatible dictionary
 */
- (NSDictionary *)toDictionary;

/**
 * Create device model from CoreBluetooth peripheral
 */
+ (instancetype)deviceFromPeripheral:(id)peripheral
                   advertisementData:(NSDictionary *)advertisementData
                                RSSI:(NSNumber *)rssi;

@end

NS_ASSUME_NONNULL_END
