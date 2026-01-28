#import "BleLockManager.h"

#import <HXJBLESDK/HXBluetoothLockHelper.h>
#import <HXJBLESDK/HXAddBluetoothLockHelper.h>
#import <HXJBLESDK/SHAdvertisementModel.h>
#import <HXJBLESDK/SHBLEHotelLockSystemParam.h>
#import <HXJBLESDK/HXBLEDeviceStatus.h>

#import "BleScanManager.h"
#import "HxjBleClient.h"
#import "OneShotResult.h"
#import "PluginUtils.h"

@interface BleLockManager ()
@property (nonatomic, strong) HxjBleClient *bleClient;
@property (nonatomic, strong) BleScanManager *scanManager;
@end

@implementation BleLockManager

- (instancetype)initWithBleClient:(HxjBleClient *)bleClient scanManager:(BleScanManager *)scanManager {
    self = [super init];
    if (self) {
        _bleClient = bleClient;
        _scanManager = scanManager;
    }
    return self;
}

- (BOOL)configureLockFromArgs:(NSDictionary *)args error:(FlutterError * __autoreleasing *)errorOut {
    NSString *mac = [PluginUtils lockMacFromArgs:args];
    NSString *aesKey = [PluginUtils stringArg:args key:@"dnaKey"];
    NSString *authCode = [PluginUtils stringArg:args key:@"authCode"];
    int keyGroupId = [PluginUtils intFromArgs:args key:@"keyGroupId" defaultValue:900];

    // Android supports either `bleProtocolVer` or `protocolVer`.
    int bleProtocolVer = 0;
    if (args[@"bleProtocolVer"] != nil) {
        bleProtocolVer = [PluginUtils intFromArgs:args key:@"bleProtocolVer" defaultValue:0];
    } else {
        bleProtocolVer = [PluginUtils intFromArgs:args key:@"protocolVer" defaultValue:0];
    }

    if (mac.length == 0) {
        if (errorOut) *errorOut = [FlutterError errorWithCode:@"ERROR" message:@"mac is required" details:nil];
        return NO;
    }

    if (aesKey.length == 0) {
        // Mirror Android local error constant meaning (DNA key empty)
        if (errorOut) *errorOut = [FlutterError errorWithCode:@"ERROR" message:@"dnaKey is required" details:nil];
        return NO;
    }

    if (authCode.length == 0) {
        if (errorOut) *errorOut = [FlutterError errorWithCode:@"ERROR" message:@"authCode is required" details:nil];
        return NO;
    }

    [HXBluetoothLockHelper setDeviceAESKey:aesKey authCode:authCode keyGroupId:keyGroupId bleProtocolVersion:bleProtocolVer lockMac:mac];
    self.bleClient.lastConnectedMac = mac;
    return YES;
}

- (void)openLock:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];

    // Validate args
    if (![args isKindOfClass:[NSDictionary class]] || args.count == 0) {
        [one error:@"ERROR" message:@"Invalid args for openLock" details:nil];
        return;
    }

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper unlockWithMac:mac synchronizeTime:NO completionBlock:^(KSHStatusCode statusCode, NSString *reason, NSString *macOut, int power, int unlockingDuration) {
            @try {
                (void)macOut; (void)power; (void)unlockingDuration;
                if (statusCode == KSHStatusCode_Success) {
                    [one success:@YES];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"Code: %ld - %@", (long)statusCode, reason ?: @""];
                    [one error:@"FAILED" message:msg details:nil];
                }
                [self.bleClient disConnectBle:nil];
            } @catch (NSException *exception) {
                NSLog(@"[BleLockManager] Exception in openLock callback: %@", exception);
                [one error:@"ERROR" message:exception.reason ?: @"Exception in openLock" details:nil];
                [self.bleClient disConnectBle:nil];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[BleLockManager] Exception calling openLock: %@", exception);
        [one error:@"ERROR" message:exception.reason ?: @"Exception calling openLock" details:nil];
    }
}

- (void)closeLock:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];

    // Validate args
    if (![args isKindOfClass:[NSDictionary class]] || args.count == 0) {
        [one error:@"ERROR" message:@"Invalid args for closeLock" details:nil];
        return;
    }

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper closeLockWithMac:mac completionBlock:^(KSHStatusCode statusCode, NSString *reason, NSString *macOut) {
            @try {
                (void)reason; (void)macOut;
                if (statusCode == KSHStatusCode_Success) {
                    [one success:@YES];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"Code: %ld - %@", (long)statusCode, reason ?: @""];
                    [one error:@"FAILED" message:msg details:nil];
                }
            } @catch (NSException *exception) {
                NSLog(@"[BleLockManager] Exception in closeLock callback: %@", exception);
                [one error:@"ERROR" message:exception.reason ?: @"Exception in closeLock" details:nil];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[BleLockManager] Exception calling closeLock: %@", exception);
        [one error:@"ERROR" message:exception.reason ?: @"Exception calling closeLock" details:nil];
    }
}
/**
 * Get system parameters and status information from lock
 * Uses iOS SDK method: getDeviceStatusWithMac:completionBlock:
 * Returns HXBLEDeviceStatus with comprehensive lock status
 */
- (void)getSysParam:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];

    // Validate args
    if (![args isKindOfClass:[NSDictionary class]] || args.count == 0) {
        [one error:@"ERROR" message:@"Invalid args for getSysParam" details:nil];
        return;
    }

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper getDeviceStatusWithMac:mac completionBlock:^(KSHStatusCode statusCode, NSString *reason, HXBLEDeviceStatus *deviceStatus) {
            @try {
                [self.bleClient disConnectBle:nil]; // Always disconnect
                
                if (statusCode == KSHStatusCode_Success && deviceStatus != nil) {
                    // Convert HXBLEDeviceStatus to Map (match Android format)
                    NSMutableDictionary *params = [NSMutableDictionary dictionary];
                    params[@"deviceStatusStr"] = deviceStatus.deviceStatusStr ?: @"";
                    params[@"lockMac"] = deviceStatus.lockMac ?: mac;
                    params[@"openMode"] = @(deviceStatus.openMode);
                    params[@"normallyOpenMode"] = @(deviceStatus.normallyOpenMode);
                    params[@"normallyopenFlag"] = @(deviceStatus.normallyopenFlag);
                    params[@"volumeEnable"] = @(deviceStatus.volumeEnable);
                    params[@"shackleAlarmEnable"] = @(deviceStatus.shackleAlarmEnable);
                    params[@"tamperSwitchStatus"] = @(deviceStatus.tamperSwitchStatus);
                    params[@"lockCylinderAlarmEnable"] = @(deviceStatus.lockCylinderAlarmEnable);
                    params[@"cylinderSwitchStatus"] = @(deviceStatus.cylinderSwitchStatus);
                    params[@"antiLockEnable"] = @(deviceStatus.antiLockEnable);
                    params[@"antiLockStatues"] = @(deviceStatus.antiLockStatues);
                    params[@"lockCoverAlarmEnable"] = @(deviceStatus.lockCoverAlarmEnable);
                    params[@"lockCoverSwitchStatus"] = @(deviceStatus.lockCoverSwitchStatus);
                    params[@"systemTimeTimestamp"] = @(deviceStatus.systemTimeTimestamp);
                    params[@"timezoneOffset"] = @(deviceStatus.timezoneOffset);
                    params[@"systemVolume"] = @(deviceStatus.systemVolume);
                    params[@"power"] = @(deviceStatus.power);
                    params[@"lowPowerUnlockTimes"] = @(deviceStatus.lowPowerUnlockTimes);
                    params[@"enableKeyType"] = @(deviceStatus.enableKeyType);
                    params[@"squareTongueStatues"] = @(deviceStatus.squareTongueStatues);
                    params[@"obliqueTongueStatues"] = @(deviceStatus.obliqueTongueStatues);
                    params[@"systemLanguage"] = @(deviceStatus.systemLanguage);
                    params[@"menuFeature"] = @""; // Not available in HXBLEDeviceStatus
                    
                    [one success:params];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"Code: %ld - %@", (long)statusCode, reason ?: @""];
                    [one error:@"FAILED" message:msg details:nil];
                }
            } @catch (NSException *exception) {
                NSLog(@"[BleLockManager] Exception in getSysParam callback: %@", exception);
                [one error:@"ERROR" message:exception.reason ?: @"Exception in getSysParam" details:nil];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[BleLockManager] Exception calling getSysParam: %@", exception);
        [one error:@"ERROR" message:exception.reason ?: @"Exception calling getSysParam" details:nil];
    }
}

@end
- (void)setKeyExpirationAlarmTime:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    int time = [PluginUtils intFromArgs:args key:@"time" defaultValue:0];
    NSString *mac = [PluginUtils lockMacFromArgs:args];

    SHBLEHotelLockSystemParam *param = [[SHBLEHotelLockSystemParam alloc] init];
    param.lockMac = mac;
    // Validate args
    if (![args isKindOfClass:[NSDictionary class]] || args.count == 0) {
        [one error:@"ERROR" message:@"Invalid args for deleteLock" details:nil];
        return;
    }

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper deleteDeviceWithMac:mac completionBlock:^(KSHStatusCode statusCode, NSString *reason) {
            @try {
                (void)reason;
                [self.bleClient disConnectBle:nil];
                if (statusCode == KSHStatusCode_Success) {
                    [one success:@YES];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"Code: %ld - %@", (long)statusCode, reason ?: @""];
                    [one error:@"FAILED" message:msg details:nil];
                }
            } @catch (NSException *exception) {
                NSLog(@"[BleLockManager] Exception in deleteLock callback: %@", exception);
                [one error:@"ERROR" message:exception.reason ?: @"Exception in deleteLock" details:nil];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[BleLockManager] Exception calling deleteLock: %@", exception);
        [one error:@"ERROR" message:exception.reason ?: @"Exception calling deleteLock" details:nil];
    }(![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    [HXBluetoothLockHelper deleteDeviceWithMac:mac completionBlock:^(KSHStatusCode statusCode, NSString *reason) {
        (void)reason;
        [self.bleClient disConnectBle:nil];
        if (statusCode == KSHStatusCode_Success) {
            [one success:@YES];
        } else {
            NSString *msg = [NSString stringWithFormat:@"Code: %ld", (long)statusCode];
            [one error:@"FAILED" message:msg details:nil];
        }
    }];
}

- (void)getDna:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    [HXBluetoothLockHelper getDNAInfoWithLockMac:mac completionBlock:^(KSHStatusCode statusCode, NSString *reason, HXBLEDeviceBase *deviceBase) {
        (void)reason; (void)deviceBase;
        if (statusCode == KSHStatusCode_Success) {
            // Android only returns a map with mac.
            [one success:@{ @"mac": mac ?: @"" }];
        } else {
            NSString *msg = [NSString stringWithFormat:@"Code: %ld", (long)statusCode];
            [one error:@"FAILED" message:msg details:nil];
        }
    }];
}

- (void)addDevice:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];
    NSLog(@"[BleLockManager] addDevice called with args: %@", args);

    // Validate args
    if (![args isKindOfClass:[NSDictionary class]] || args.count == 0) {
        [one error:@"ERROR" message:@"Invalid args for addDevice" details:nil];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];
    if (mac.length == 0) {
        [one error:@"ERROR" message:@"mac is required" details:nil];
        return;
    }

    // Find advertisement from recent scan
    SHAdvertisementModel *ad = [self.scanManager advertisementForMac:mac];
    if (!ad) {
        [one error:@"FAILED" message:@"Device not found in scan results. Please scan first." details:nil];
        return;
    }

    @try {
        HXAddBluetoothLockHelper *helper = [[HXAddBluetoothLockHelper alloc] init];
        [helper startAddDeviceWithAdvertisementModel:ad completionBlock:^(KSHStatusCode statusCode, NSString *reason, HXBLEDevice *device, HXBLEDeviceStatus *deviceStatus) {
            @try {
                if (statusCode == KSHStatusCode_Success && device != nil && deviceStatus != nil) {
                    // CRITICAL FIX: Return DNA info Map (match Android)
                    NSMutableDictionary *dnaMap = [NSMutableDictionary dictionary];
                    dnaMap[@"mac"] = device.lockMac ?: mac;
                    dnaMap[@"authCode"] = device.adminAuthCode ?: @"";
                    dnaMap[@"dnaKey"] = device.adminAes128Key ?: @"";
                    dnaMap[@"protocolVer"] = @(device.bleProtocolVersion);
                    dnaMap[@"deviceType"] = @(device.deviceType);
                    dnaMap[@"hardwareVer"] = device.hardWareVer ?: @"";
                    dnaMap[@"softwareVer"] = device.softWareVer ?: @"";
                    dnaMap[@"rFModuleType"] = @(device.rFMoudleType);
                    dnaMap[@"rFModuleMac"] = device.rFModuleMac ?: @"";
                    dnaMap[@"menuFeature"] = deviceStatus.menuFeature ?: @"0";
                    dnaMap[@"deviceDnaInfoStr"] = device.deviceDnaInfoStr ?: @"";
                    dnaMap[@"keyGroupId"] = @900; // Always 900

                    [one success:dnaMap];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"addDevice failed: Code %ld - %@", (long)statusCode, reason ?: @"Unknown error"];
                    [one error:@"FAILED" message:msg details:nil];
                }
            } @catch (NSException *exception) {
                NSLog(@"[BleLockManager] Exception in addDevice callback: %@", exception);
                [one error:@"ERROR" message:exception.reason ?: @"Exception in addDevice" details:nil];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[BleLockManager] Exception calling addDevice: %@", exception);
        [one error:@"ERROR" message:exception.reason ?: @"Exception calling addDevice" details:nil];
    }
