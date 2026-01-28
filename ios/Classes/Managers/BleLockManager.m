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

#pragma mark - Helpers

- (BOOL)validateArgs:(NSDictionary *)args method:(NSString *)method one:(OneShotResult *)one {
    if (![args isKindOfClass:[NSDictionary class]] || args.count == 0) {
        NSString *msg = [NSString stringWithFormat:@"Invalid args for %@", method ?: @"method"];
        [one error:@"ERROR" message:msg details:nil];
        return NO;
    }
    return YES;
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
        if (errorOut) *errorOut = [FlutterError errorWithCode:@"ERROR" message:@"dnaKey is required" details:nil];
        return NO;
    }

    if (authCode.length == 0) {
        if (errorOut) *errorOut = [FlutterError errorWithCode:@"ERROR" message:@"authCode is required" details:nil];
        return NO;
    }

    [HXBluetoothLockHelper setDeviceAESKey:aesKey
                                 authCode:authCode
                               keyGroupId:keyGroupId
                        bleProtocolVersion:bleProtocolVer
                                  lockMac:mac];

    self.bleClient.lastConnectedMac = mac;
    return YES;
}

#pragma mark - Public API (called from channel handler)

- (void)openLock:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];
    if (![self validateArgs:args method:@"openLock" one:one]) return;

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper unlockWithMac:mac
                            synchronizeTime:NO
                           completionBlock:^(KSHStatusCode statusCode,
                                             NSString *reason,
                                             NSString *macOut,
                                             int power,
                                             int unlockingDuration) {
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
    if (![self validateArgs:args method:@"closeLock" one:one]) return;

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper closeLockWithMac:mac
                               completionBlock:^(KSHStatusCode statusCode,
                                                 NSString *reason,
                                                 NSString *macOut) {
            @try {
                (void)macOut;
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
    if (![self validateArgs:args method:@"getSysParam" one:one]) return;

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper getDeviceStatusWithMac:mac
                                     completionBlock:^(KSHStatusCode statusCode,
                                                       NSString *reason,
                                                       HXBLEDeviceStatus *deviceStatus) {
            @try {
                [self.bleClient disConnectBle:nil]; // Always disconnect

                if (statusCode == KSHStatusCode_Success && deviceStatus != nil) {
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

                    // Not available in HXBLEDeviceStatus (kept for Android parity)
                    params[@"menuFeature"] = @"";

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

- (void)setKeyExpirationAlarmTime:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];
    if (![self validateArgs:args method:@"setKeyExpirationAlarmTime" one:one]) return;

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    // You started using SHBLEHotelLockSystemParam, but the actual HXJ iOS API call
    // for setting key expiration alarm time is not provided in the snippet.
    // Keep this method compiling safely until you confirm the correct SDK method.
    (void)[PluginUtils intFromArgs:args key:@"time" defaultValue:0];
    (void)[PluginUtils lockMacFromArgs:args];

    SHBLEHotelLockSystemParam *param = [[SHBLEHotelLockSystemParam alloc] init];
    param.lockMac = [PluginUtils lockMacFromArgs:args];
    (void)param;

    [one error:@"UNIMPLEMENTED"
        message:@"setKeyExpirationAlarmTime is not implemented yet on iOS."
        details:nil];
}

- (void)deleteLock:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];
    if (![self validateArgs:args method:@"deleteLock" one:one]) return;

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper deleteDeviceWithMac:mac completionBlock:^(KSHStatusCode statusCode, NSString *reason) {
            @try {
                [self.bleClient disConnectBle:nil];
                if (statusCode == KSHStatusCode_Success) {
                    [one success:@YES];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"Code: %ld - %@", (long)statusCode, reason ?: @""];
                    [one error:@"FAILED" message:msg details:nil];
                }
            } @catch (NSException *exception) {
                NSLog(@"[BleLockManager] Exception in deleteLock callback: %@", exception);
                [self.bleClient disConnectBle:nil];
                [one error:@"ERROR" message:exception.reason ?: @"Exception in deleteLock" details:nil];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[BleLockManager] Exception calling deleteLock: %@", exception);
        [one error:@"ERROR" message:exception.reason ?: @"Exception calling deleteLock" details:nil];
    }
}

- (void)getDna:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];
    if (![self validateArgs:args method:@"getDna" one:one]) return;

    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [one error:cfgErr.code message:cfgErr.message details:cfgErr.details];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];

    @try {
        [HXBluetoothLockHelper getDNAInfoWithLockMac:mac completionBlock:^(KSHStatusCode statusCode, NSString *reason, HXBLEDeviceBase *deviceBase) {
            @try {
                (void)reason; (void)deviceBase;
                if (statusCode == KSHStatusCode_Success) {
                    [one success:@{ @"mac": mac ?: @"" }];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"Code: %ld - %@", (long)statusCode, reason ?: @""];
                    [one error:@"FAILED" message:msg details:nil];
                }
            } @catch (NSException *exception) {
                NSLog(@"[BleLockManager] Exception in getDna callback: %@", exception);
                [one error:@"ERROR" message:exception.reason ?: @"Exception in getDna" details:nil];
            }
        }];
    } @catch (NSException *exception) {
        NSLog(@"[BleLockManager] Exception calling getDna: %@", exception);
        [one error:@"ERROR" message:exception.reason ?: @"Exception calling getDna" details:nil];
    }
}

- (void)addDevice:(NSDictionary *)args result:(FlutterResult)result {
    OneShotResult *one = [[OneShotResult alloc] initWithResult:result];
    NSLog(@"[BleLockManager] addDevice called with args: %@", args);

    if (![self validateArgs:args method:@"addDevice" one:one]) return;

    NSString *mac = [PluginUtils lockMacFromArgs:args];
    if (mac.length == 0) {
        [one error:@"ERROR" message:@"mac is required" details:nil];
        return;
    }

    // Try to get advertisement model from args first, then fall back to scan manager
    SHAdvertisementModel *advertisementModel = nil;
    
    // Check if device data is provided directly in args (from HxjBluetoothDeviceModel.toMap())
    if (args[@"name"] || args[@"RSSI"] || args[@"chipType"] || args[@"lockType"]) {
        advertisementModel = [[SHAdvertisementModel alloc] init];
        advertisementModel.mac = mac;
        
        // Set fields from args (match iOS Flutter model keys from _toIosMap)
        if (args[@"name"]) advertisementModel.name = args[@"name"];
        if (args[@"RSSI"]) advertisementModel.rssi = [args[@"RSSI"] intValue];
        if (args[@"chipType"]) advertisementModel.chipType = [args[@"chipType"] intValue];
        if (args[@"lockType"]) advertisementModel.lockType = [args[@"lockType"] intValue];
        if (args[@"isPairedFlag"]) advertisementModel.isPairedFlag = [args[@"isPairedFlag"] boolValue];
        if (args[@"discoverableFlag"]) advertisementModel.discoverableFlag = [args[@"discoverableFlag"] boolValue];
        if (args[@"modernProtocol"]) advertisementModel.modernProtocol = [args[@"modernProtocol"] boolValue];
        if (args[@"serviceUUIDs"]) advertisementModel.serviceUUIDs = args[@"serviceUUIDs"];
    } else {
        // Fall back to scan manager if no device data in args
        advertisementModel = [self.scanManager advertisementForMac:mac];
    }
    
    if (!advertisementModel) {
        [one error:@"FAILED" message:@"Device not found. Provide advertisementData or scan first." details:nil];
        return;
    }

    @try {
        HXAddBluetoothLockHelper *helper = [[HXAddBluetoothLockHelper alloc] init];
        [helper startAddDeviceWithAdvertisementModel:advertisementModel 
                                     completionBlock:^(KSHStatusCode statusCode,
                                                      NSString *reason,
                                                      HXBLEDevice *device,
                                                      HXBLEDeviceStatus *deviceStatus) {
            @try {
                if (statusCode == KSHStatusCode_Success && device != nil && deviceStatus != nil) {
                    NSMutableDictionary *dnaMap = [NSMutableDictionary dictionary];
                    dnaMap[@"mac"] = device.lockMac ?: mac;
                    dnaMap[@"authCode"] = device.adminAuthCode ?: @"";
                    dnaMap[@"dnaKey"] = device.aesKey ?: @"";
                    dnaMap[@"protocolVer"] = @(device.bleProtocolVersion);
                    dnaMap[@"deviceType"] = @(device.lockType) ?: @"";
                    dnaMap[@"hardwareVer"] = device.hardwareVersion ?: @"";
                    dnaMap[@"softwareVer"] = device.rfMoudleSoftwareVer ?: @"";
                    dnaMap[@"rFModuleType"] = @(device.rfModuleType);
                    dnaMap[@"rFModuleMac"] = device.rfModuleMac ?: @"";
//                    dnaMap[@"menuFeature"] = deviceStatus. ?: @"0";
                    dnaMap[@"deviceDnaInfoStr"] = device.deviceDnaInfoStr ?: @"";
                    dnaMap[@"keyGroupId"] = @900;

                    [one success:dnaMap];
                } else {
                    NSString *msg = [NSString stringWithFormat:@"addDevice failed: Code %ld - %@",
                                     (long)statusCode,
                                     reason ?: @"Unknown error"];
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
}

@end
