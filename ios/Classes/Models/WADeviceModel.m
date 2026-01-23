//
//  WADeviceModel.m
//  wise_apartment
//
//  Device model implementation
//

#import "WADeviceModel.h"
#import <CoreBluetooth/CoreBluetooth.h>

@implementation WADeviceModel

- (NSDictionary *)toDictionary {
    NSMutableDictionary *dict = [NSMutableDictionary dictionary];
    
    dict[@"deviceId"] = self.deviceId ?: @"";
    dict[@"name"] = self.name ?: @"Unknown Device";
    
    if (self.rssi) {
        dict[@"rssi"] = self.rssi;
    }
    
    if (self.manufacturerData) {
        dict[@"manufacturerData"] = self.manufacturerData;
    }
    
    if (self.advertisementData) {
        dict[@"advertisementData"] = self.advertisementData;
    }
    
    if (self.deviceType) {
        dict[@"deviceType"] = self.deviceType;
    }
    
    return [dict copy];
}

+ (instancetype)deviceFromPeripheral:(CBPeripheral *)peripheral
                   advertisementData:(NSDictionary *)advertisementData
                                RSSI:(NSNumber *)rssi {
    
    WADeviceModel *device = [[WADeviceModel alloc] init];
    
    device.deviceId = peripheral.identifier.UUIDString;
    device.name = peripheral.name ?: advertisementData[CBAdvertisementDataLocalNameKey] ?: @"Unknown Device";
    device.rssi = rssi;
    
    // Extract manufacturer data
    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (manufacturerData) {
        device.manufacturerData = [manufacturerData base64EncodedStringWithOptions:0];
    }
    
    // Build advertisement data dictionary
    NSMutableDictionary *adData = [NSMutableDictionary dictionary];
    if (advertisementData[CBAdvertisementDataLocalNameKey]) {
        adData[@"localName"] = advertisementData[CBAdvertisementDataLocalNameKey];
    }
    if (advertisementData[CBAdvertisementDataTxPowerLevelKey]) {
        adData[@"txPowerLevel"] = advertisementData[CBAdvertisementDataTxPowerLevelKey];
    }
    if (advertisementData[CBAdvertisementDataServiceUUIDsKey]) {
        NSArray *serviceUUIDs = advertisementData[CBAdvertisementDataServiceUUIDsKey];
        NSMutableArray *uuidStrings = [NSMutableArray array];
        for (CBUUID *uuid in serviceUUIDs) {
            [uuidStrings addObject:uuid.UUIDString];
        }
        adData[@"serviceUUIDs"] = uuidStrings;
    }
    device.advertisementData = [adData copy];
    
    return device;
}

@end
