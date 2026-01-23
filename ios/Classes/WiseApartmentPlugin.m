//
//  WiseApartmentPlugin.m
//  wise_apartment
//
//  Main plugin implementation bridging Flutter ↔ Native SDK
//

#import "WiseApartmentPlugin.h"
#import "WAEventEmitter.h"
#import "WAScanManager.h"
#import "WAPairManager.h"
#import "WAWiFiConfigManager.h"
#import "WABluetoothStateManager.h"
#import "WAErrorHandler.h"

// Channel names (MUST match Flutter side exactly)
static NSString *const kMethodChannelName = @"wise_apartment/methods";
static NSString *const kEventChannelName = @"wise_apartment/events";

@interface WiseApartmentPlugin ()

@property (nonatomic, strong) FlutterMethodChannel *methodChannel;
@property (nonatomic, strong) FlutterEventChannel *eventChannel;
@property (nonatomic, strong) WAEventEmitter *eventEmitter;

// Manager instances
@property (nonatomic, strong) WAScanManager *scanManager;
@property (nonatomic, strong) WAPairManager *pairManager;
@property (nonatomic, strong) WAWiFiConfigManager *wifiManager;
@property (nonatomic, strong) WABluetoothStateManager *bluetoothStateManager;

@end

@implementation WiseApartmentPlugin

#pragma mark - Plugin Registration

+ (void)registerWithRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    WiseApartmentPlugin *instance = [[WiseApartmentPlugin alloc] init];
    
    // Setup MethodChannel
    instance.methodChannel = [FlutterMethodChannel
                             methodChannelWithName:kMethodChannelName
                             binaryMessenger:[registrar messenger]];
    [registrar addMethodCallDelegate:instance channel:instance.methodChannel];
    
    // Setup EventChannel
    instance.eventChannel = [FlutterEventChannel
                            eventChannelWithName:kEventChannelName
                            binaryMessenger:[registrar messenger]];
    [instance.eventChannel setStreamHandler:instance];
}

#pragma mark - Lifecycle

- (instancetype)init {
    self = [super init];
    if (self) {
        [self setupComponents];
    }
    return self;
}

- (void)setupComponents {
    // Initialize event emitter (shared by all managers)
    self.eventEmitter = [[WAEventEmitter alloc] init];
    
    // Initialize managers
    self.bluetoothStateManager = [[WABluetoothStateManager alloc] initWithEventEmitter:self.eventEmitter];
    self.scanManager = [[WAScanManager alloc] initWithEventEmitter:self.eventEmitter];
    self.pairManager = [[WAPairManager alloc] initWithEventEmitter:self.eventEmitter];
    self.wifiManager = [[WAWiFiConfigManager alloc] initWithEventEmitter:self.eventEmitter];
}

- (void)detachFromEngineForRegistrar:(NSObject<FlutterPluginRegistrar>*)registrar {
    [self cleanup];
}

- (void)cleanup {
    // Stop all ongoing operations
    [self.scanManager stopScan];
    [self.pairManager cancelPairing];
    [self.wifiManager cancelConfiguration];
    
    // Clear event sink
    [self.eventEmitter clearEventSink];
    
    // Nullify channels
    self.methodChannel = nil;
    self.eventChannel = nil;
}

#pragma mark - FlutterStreamHandler (EventChannel)

- (FlutterError* _Nullable)onListenWithArguments:(id _Nullable)arguments
                                       eventSink:(FlutterEventSink)events {
    // Store event sink for streaming events to Flutter
    [self.eventEmitter setEventSink:events];
    return nil;
}

- (FlutterError* _Nullable)onCancelWithArguments:(id _Nullable)arguments {
    // Clear event sink when Flutter stops listening
    [self.eventEmitter clearEventSink];
    return nil;
}

#pragma mark - FlutterPlugin (MethodChannel)

- (void)handleMethodCall:(FlutterMethodCall*)call result:(FlutterResult)result {
    NSString *method = call.method;
    id args = call.arguments;
    
    // Platform/Device Info Methods
    if ([@"getPlatformVersion" isEqualToString:method]) {
        [self handleGetPlatformVersion:result];
    }
    else if ([@"getDeviceInfo" isEqualToString:method]) {
        [self handleGetDeviceInfo:result];
    }
    else if ([@"getAndroidBuildConfig" isEqualToString:method]) {
        [self handleGetAndroidBuildConfig:result];
    }
    // BLE Initialization & Scanning
    else if ([@"initBleClient" isEqualToString:method]) {
        [self handleInitBleClient:result];
    }
    else if ([@"startScan" isEqualToString:method]) {
        [self handleStartScan:args result:result];
    }
    else if ([@"stopScan" isEqualToString:method]) {
        [self handleStopScan:result];
    }
    // Device Management
    else if ([@"addDevice" isEqualToString:method]) {
        [self handleAddDevice:args result:result];
    }
    else if ([@"deleteLock" isEqualToString:method]) {
        [self handleDeleteLock:args result:result];
    }
    else if ([@"getDna" isEqualToString:method]) {
        [self handleGetDna:args result:result];
    }
    // Lock Operations
    else if ([@"openLock" isEqualToString:method]) {
        [self handleOpenLock:args result:result];
    }
    else if ([@"closeLock" isEqualToString:method]) {
        [self handleCloseLock:args result:result];
    }
    // WiFi Configuration
    else if ([@"regWifi" isEqualToString:method]) {
        [self handleRegisterWifi:args result:result];
    }
    // BLE Connection
    else if ([@"connectBle" isEqualToString:method]) {
        [self handleConnectBle:args result:result];
    }
    else if ([@"disconnectBle" isEqualToString:method]) {
        [self handleDisconnectBle:result];
    }
    else if ([@"disconnect" isEqualToString:method]) {
        [self handleDisconnect:args result:result];
    }
    // Network Info
    else if ([@"getNBIoTInfo" isEqualToString:method]) {
        [self handleGetNBIoTInfo:args result:result];
    }
    else if ([@"getCat1Info" isEqualToString:method]) {
        [self handleGetCat1Info:args result:result];
    }
    // Lock Configuration
    else if ([@"setKeyExpirationAlarmTime" isEqualToString:method]) {
        [self handleSetKeyExpirationAlarmTime:args result:result];
    }
    else if ([@"syncLockRecords" isEqualToString:method]) {
        [self handleSyncLockRecords:args result:result];
    }
    else if ([@"syncLockRecordsPage" isEqualToString:method]) {
        [self handleSyncLockRecordsPage:args result:result];
    }
    else if ([@"addLockKey" isEqualToString:method]) {
        [self handleAddLockKey:args result:result];
    }
    else if ([@"syncLockKey" isEqualToString:method]) {
        [self handleSyncLockKey:args result:result];
    }
    else if ([@"syncLockTime" isEqualToString:method]) {
        [self handleSyncLockTime:args result:result];
    }
    else if ([@"getSysParam" isEqualToString:method]) {
        [self handleGetSysParam:args result:result];
    }
    // SDK State
    else if ([@"clearSdkState" isEqualToString:method]) {
        [self handleClearSdkState:result];
    }
    else {
        result(FlutterMethodNotImplemented);
    }
}

#pragma mark - Method Handlers

// Platform/Device Info Methods

- (void)handleGetPlatformVersion:(FlutterResult)result {
    NSString *version = [NSString stringWithFormat:@"iOS %@", [[UIDevice currentDevice] systemVersion]];
    result(version);
}

- (void)handleGetDeviceInfo:(FlutterResult)result {
    UIDevice *device = [UIDevice currentDevice];
    NSDictionary *info = @{
        @"model": device.model ?: @"",
        @"name": device.name ?: @"",
        @"systemName": device.systemName ?: @"",
        @"systemVersion": device.systemVersion ?: @"",
        @"identifierForVendor": device.identifierForVendor.UUIDString ?: @"",
        @"platform": @"iOS"
    };
    result(info);
}

- (void)handleGetAndroidBuildConfig:(FlutterResult)result {
    // iOS doesn't have Android build config - return null/empty
    result(nil);
}

// BLE Initialization & Scanning

- (void)handleInitBleClient:(FlutterResult)result {
    // Check Bluetooth availability
    if (![self.bluetoothStateManager isBluetoothAvailable]) {
        result(@NO);
        return;
    }
    
    // TODO: Initialize SDK BLE client if needed
    // Example: [[HXBleClient shared] initialize];
    
    result(@YES);
}

- (void)handleStartScan:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : @{};
    
    // Validate Bluetooth state
    if (![self.bluetoothStateManager isBluetoothPoweredOn]) {
        result([WAErrorHandler flutterErrorWithCode:WAErrorCodeBluetoothOff
                                            message:@"Bluetooth is turned off"
                                            details:nil]);
        return;
    }
    
    // Extract parameters (with defaults matching Android)
    NSNumber * timeoutMs = params[@"timeoutMs"] ?: @10000;
    
    // Start scan and collect results
    NSError *error = nil;
    BOOL success = [self.scanManager startScanWithTimeout:[timeoutMs integerValue]/1000.0
                                          allowDuplicates:NO
                                                    error:&error];
    
    if (!success) {
        result([WAErrorHandler flutterErrorFromNSError:error]);
        return;
    }
    
    // Android returns List<Map> after scan completes
    // For now, return empty array (scan results come via events in real impl)
    // TODO: Collect scan results and return them after timeout
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)([timeoutMs doubleValue]/1000.0 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        // Return collected devices (in real implementation, store discovered devices)
        result(@[]);
    });
}

- (void)handleStopScan:(FlutterResult)result {
    [self.scanManager stopScan];
    result(@YES);
}

// Device Management

- (void)handleAddDevice:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!params) {
        result([WAErrorHandler flutterErrorWithCode:WAErrorCodeInvalidParameters
                                            message:@"Invalid parameters - expected Map"
                                            details:nil]);
        return;
    }
    
    NSString *mac = params[@"mac"];
    NSNumber *chipType = params[@"chipType"];
    
    if (!mac || !chipType) {
        result([WAErrorHandler flutterErrorWithCode:WAErrorCodeInvalidParameters
                                            message:@"mac and chipType are required"
                                            details:nil]);
        return;
    }
    
    // TODO: Call SDK addDevice
    // Example: [[HXDeviceManager shared] addDeviceWithMac:mac chipType:[chipType intValue] completion:^(NSDictionary *dna, NSError *error) { ... }];
    
    // Simulate orchestrated response matching Android
    NSDictionary *dnaInfo = @{
        @"mac": mac,
        @"authCode": @"000000",
        @"dnaKey": @"",
        @"protocolVer": @2,
        @"deviceType": chipType
    };
    
    NSDictionary *response = @{
        @"ok": @YES,
        @"stage": @"complete",
        @"dnaInfo": dnaInfo,
        @"sysParam": @{},
        @"responses": @{
            @"addDevice": @{@"code": @0, @"isSuccessful": @YES},
            @"getSysParam": @{@"code": @0, @"isSuccessful": @YES},
            @"pairSuccessInd": @{@"code": @0, @"isSuccessful": @YES}
        }
    };
    result(response);
}

- (void)handleDeleteLock:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth) {
        result(@NO);
        return;
    }
    
    // TODO: Call SDK deleteLock
    // Example: [[HXLockManager shared] deleteLockWithAuth:auth completion:^(BOOL success) { ... }];
    
    result(@YES);
}

- (void)handleGetDna:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth) {
        result(@{});
        return;
    }
    
    // TODO: Call SDK getDna
    // Example: [[HXDeviceManager shared] getDnaWithAuth:auth completion:^(NSDictionary *dna) { ... }];
    
    result(auth); // Return auth as DNA for now
}

// Lock Operations

- (void)handleOpenLock:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth || !auth[@"mac"]) {
        result(@NO);
        return;
    }
    
    // TODO: Call SDK openLock
    // Example: [[HXLockManager shared] openLockWithAuth:auth completion:^(BOOL success) { ... }];
    
    result(@YES);
}

- (void)handleCloseLock:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth || !auth[@"mac"]) {
        result(@NO);
        return;
    }
    
    // TODO: Call SDK closeLock
    // Example: [[HXLockManager shared] closeLockWithAuth:auth completion:^(BOOL success) { ... }];
    
    result(@YES);
}

// WiFi Configuration

- (void)handleRegisterWifi:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!params) {
        result(@{@"success": @NO, @"message": @"Invalid parameters - expected Map"});
        return;
    }
    
    NSString *wifiJson = params[@"wifi"];
    NSString *mac = params[@"mac"];
    NSDictionary *dna = params[@"dna"];
    
    if (!wifiJson) {
        result(@{@"success": @NO, @"message": @"wifi parameter is required"});
        return;
    }
    
    // TODO: Call SDK registerWifi
    // Example: [[HXWiFiManager shared] registerWifiWithConfig:wifiJson mac:mac dna:dna completion:^(NSDictionary *result) { ...}];
    
    result(@{@"success": @YES, @"code": @0, @"message": @"WiFi registered"});
}

// BLE Connection

- (void)handleConnectBle:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth || !auth[@"mac"]) {
        result(@NO);
        return;
    }
    
    // TODO: Call SDK connectBle
    // Example: [[HXBleClient shared] connectWithAuth:auth completion:^(BOOL success) { ... }];
    
    result(@YES);
}

- (void)handleDisconnectBle:(FlutterResult)result {
    //TODO: Call SDK disconnectBle
    // Example: [[HXBleClient shared] disconnect];
    
    result(@YES);
}

- (void)handleDisconnect:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    NSString *mac = params[@"mac"];
    
    if (!mac) {
        result(@NO);
        return;
    }
    
    // TODO: Call SDK disconnect
    // Example: [[HXBleClient shared] disconnectDevice:mac];
    
    result(@YES);
}

// Network Info

- (void)handleGetNBIoTInfo:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth) {
        result(@{});
        return;
    }
    
    // TODO: Call SDK getNBIoTInfo
    // Example: [[HXNetworkManager shared] getNBIoTInfoWithAuth:auth completion:^(NSDictionary *info) { ... }];
    
    result(@{@"code": @0, @"message": @"Not implemented on iOS"});
}

- (void)handleGetCat1Info:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth) {
        result(@{});
        return;
    }
    
    // TODO: Call SDK getCat1Info
    // Example: [[HXNetworkManager shared] getCat1InfoWithAuth:auth completion:^(NSDictionary *info) { ... }];
    
    result(@{@"code": @0, @"message": @"Not implemented on iOS"});
}

// Lock Configuration

- (void)handleSetKeyExpirationAlarmTime:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!params) {
        result(@NO);
        return;
    }
    
    NSNumber *time = params[@"time"];
    
    if (!time) {
        result(@NO);
        return;
    }
    
    // TODO: Call SDK setKeyExpirationAlarmTime
    // Example: [[HXLockManager shared] setKeyExpiration:params time:[time intValue] completion:^(BOOL success) { ... }];
    
    result(@YES);
}

- (void)handleSyncLockRecords:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!params) {
        result(@[]);
        return;
    }
    
    NSNumber *logVersion = params[@"logVersion"];
    
    // TODO: Call SDK syncLockRecords
    // Example: [[HXLockManager shared] syncRecordsWithAuth:params logVersion:[logVersion intValue] completion:^(NSArray *records) { ... }];
    
    result(@[]);
}

- (void)handleSyncLockRecordsPage:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!params) {
        result(@{@"records": @[], @"total": @0});
        return;
    }
    
    NSNumber *startNum = params[@"startNum"];
    NSNumber *readCnt = params[@"readCnt"];
    
    // TODO: Call SDK syncLockRecordsPage
    // Example: [[HXLockManager shared] syncRecordsPageWithAuth:params start:[startNum intValue] count:[readCnt intValue] completion:^(NSDictionary *result) { ... }];
    
    result(@{@"records": @[], @"total": @0});
}

- (void)handleAddLockKey:(id)args result:(FlutterResult)result {
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!params) {
        result(@{@"success": @NO});
        return;
    }
    
    // Parameters are within the dictionary itself
    // Example keys: mac, authCode, keyType, userType, etc.
    
    // TODO: Call SDK addLockKey
    // Example: [[HXKeyManager shared] addKeyWithParams:params completion:^(NSDictionary *result) { ... }];
    
    result(@{@"success": @YES, @"code": @0});
}

- (void)handleSyncLockKey:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth) {
        result(@{@"success": @NO});
        return;
    }
    
    // TODO: Call SDK syncLockKey
    // Example: [[HXKeyManager shared] syncKeysWithAuth:auth completion:^(NSDictionary *result) { ... }];
    
    result(@{@"success": @YES, @"keys": @[]});
}

- (void)handleSyncLockTime:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth) {
        result(@NO);
        return;
    }
    
    // TODO: Call SDK syncLockTime
    // Example: [[HXLockManager shared] syncTimeWithAuth:auth completion:^(BOOL success) { ... }];
    
    result(@YES);
}

- (void)handleGetSysParam:(id)args result:(FlutterResult)result {
    NSDictionary *auth = [args isKindOfClass:[NSDictionary class]] ? args : nil;
    if (!auth) {
        result(@{});
        return;
    }
    
    // TODO: Call SDK getSysParam
    // Example: [[HXLockManager shared] getSysParamWithAuth:auth completion:^(NSDictionary *params) { ... }];
    
    result(@{@"code": @0, @"body": @{}});
}

// SDK State

- (void)handleClearSdkState:(FlutterResult)result {
    // TODO: Call SDK clearState
    // Example: [[HXSDKManager shared] clearState];
    
    result(@YES);
}

@end
