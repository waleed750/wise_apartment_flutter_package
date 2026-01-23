//
//  WAScanManager.m
//  wise_apartment
//
//  BLE scanning implementation
//

#import "WAScanManager.h"
#import "WAEventEmitter.h"
#import "WAErrorHandler.h"

// TODO: Import your actual SDK headers
// #import <HXJBLESDK/HXScanAllDevicesHelper.h>
// #import <HXJBLESDK/HXScanAllDevicesHelperDelegate.h>

@interface WAScanManager () <CBCentralManagerDelegate>

@property (nonatomic, weak) WAEventEmitter *eventEmitter;
@property (nonatomic, strong) CBCentralManager *centralManager;
@property (nonatomic, strong) NSTimer *scanTimeoutTimer;
@property (nonatomic, assign) BOOL isCurrentlyScanning;
@property (nonatomic, assign) BOOL allowDuplicates;
@property (nonatomic, strong) NSMutableDictionary<NSString *, CBPeripheral *> *discoveredDevices;

// TODO: Replace with actual SDK helper
// @property (nonatomic, strong) HXScanAllDevicesHelper *sdkScanHelper;

@end

@implementation WAScanManager

- (instancetype)initWithEventEmitter:(WAEventEmitter *)eventEmitter {
    self = [super init];
    if (self) {
        _eventEmitter = eventEmitter;
        _centralManager = [[CBCentralManager alloc] initWithDelegate:self queue:nil];
        _discoveredDevices = [NSMutableDictionary dictionary];
        
        // TODO: Initialize SDK scan helper if needed
        // _sdkScanHelper = [[HXScanAllDevicesHelper alloc] init];
        // _sdkScanHelper.delegate = self;
    }
    return self;
}

- (void)dealloc {
    [self stopScan];
}

#pragma mark - Public Methods

- (BOOL)startScanWithTimeout:(NSTimeInterval)timeout
             allowDuplicates:(BOOL)allowDuplicates
                       error:(NSError **)error {
    
    if (self.isCurrentlyScanning) {
        if (error) {
            *error = [WAErrorHandler errorWithCode:WAErrorCodeScanAlreadyRunning
                                           message:nil];
        }
        return NO;
    }
    
    // Check Bluetooth state
    if (self.centralManager.state != CBManagerStatePoweredOn) {
        if (error) {
            *error = [WAErrorHandler errorWithCode:WAErrorCodeBluetoothOff
                                           message:@"Bluetooth must be powered on to scan"];
        }
        return NO;
    }
    
    self.allowDuplicates = allowDuplicates;
    [self.discoveredDevices removeAllObjects];
    
    // === OPTION 1: Using CoreBluetooth directly ===
    // Scan for all peripherals (or filter by service UUIDs if known)
    NSDictionary *options = @{
        CBCentralManagerScanOptionAllowDuplicatesKey: @(allowDuplicates)
    };
    
    // TODO: Replace nil with specific service UUIDs if known
    // Example: @[[CBUUID UUIDWithString:@"YOUR-SERVICE-UUID"]]
    [self.centralManager scanForPeripheralsWithServices:nil options:options];
    
    // === OPTION 2: Using SDK scan helper (uncomment when SDK is available) ===
    // TODO: Call SDK scan method
    // [self.sdkScanHelper startScanWithTimeout:timeout];
    
    self.isCurrentlyScanning = YES;
    
    // Emit scan started event
    [self.eventEmitter emitEvent:@{
        @"type": @"scanState",
        @"state": @"started"
    }];
    
    // Setup timeout if specified
    if (timeout > 0) {
        __weak typeof(self) weakSelf = self;
        self.scanTimeoutTimer = [NSTimer scheduledTimerWithTimeInterval:timeout
                                                                repeats:NO
                                                                  block:^(NSTimer *timer) {
            __strong typeof(weakSelf) strongSelf = weakSelf;
            [strongSelf stopScan];
        }];
    }
    
    return YES;
}

- (void)stopScan {
    if (!self.isCurrentlyScanning) {
        return;
    }
    
    [self.centralManager stopScan];
    
    // TODO: Stop SDK scan helper if used
    // [self.sdkScanHelper stopScan];
    
    [self.scanTimeoutTimer invalidate];
    self.scanTimeoutTimer = nil;
    self.isCurrentlyScanning = NO;
    
    [self.eventEmitter emitEvent:@{
        @"type": @"scanState",
        @"state": @"stopped"
    }];
}

- (BOOL)isScanning {
    return self.isCurrentlyScanning;
}

#pragma mark - CBCentralManagerDelegate

- (void)centralManagerDidUpdateState:(CBCentralManager *)central {
    NSLog(@"[WAScanManager] Bluetooth state: %ld", (long)central.state);
    
    // If scanning and BT turns off, stop scan
    if (central.state != CBManagerStatePoweredOn && self.isCurrentlyScanning) {
        [self stopScan];
        [self.eventEmitter emitEvent:@{
            @"type": @"scanState",
            @"state": @"stopped",
            @"reason": @"bluetooth_off"
        }];
    }
}

- (void)centralManager:(CBCentralManager *)central
 didDiscoverPeripheral:(CBPeripheral *)peripheral
     advertisementData:(NSDictionary<NSString *,id> *)advertisementData
                  RSSI:(NSNumber *)RSSI {
    
    // Filter out unnamed devices (optional)
    NSString *deviceName = peripheral.name ?: advertisementData[CBAdvertisementDataLocalNameKey];
    if (!deviceName || [deviceName length] == 0) {
        deviceName = @"Unknown Device";
    }
    
    // Check for duplicates (if not allowed)
    NSString *deviceId = peripheral.identifier.UUIDString;
    if (!self.allowDuplicates && self.discoveredDevices[deviceId]) {
        return; // Skip duplicate
    }
    
    self.discoveredDevices[deviceId] = peripheral;
    
    // Build device payload matching Android format
    NSMutableDictionary *devicePayload = [NSMutableDictionary dictionary];
    devicePayload[@"deviceId"] = deviceId;
    devicePayload[@"name"] = deviceName;
    devicePayload[@"rssi"] = RSSI;
    
    // Extract manufacturer data (if present)
    NSData *manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey];
    if (manufacturerData) {
        devicePayload[@"manufacturerData"] = [manufacturerData base64EncodedStringWithOptions:0];
    }
    
    // Advertisement data
    NSMutableDictionary *adData = [NSMutableDictionary dictionary];
    if (advertisementData[CBAdvertisementDataLocalNameKey]) {
        adData[@"localName"] = advertisementData[CBAdvertisementDataLocalNameKey];
    }
    if (advertisementData[CBAdvertisementDataTxPowerLevelKey]) {
        adData[@"txPowerLevel"] = advertisementData[CBAdvertisementDataTxPowerLevelKey];
    }
    devicePayload[@"advertisementData"] = adData;
    
    // Emit scan result event
    [self.eventEmitter emitEvent:@{
        @"type": @"scanResult",
        @"device": devicePayload
    }];
}

#pragma mark - SDK Delegate (TODO: Implement if using SDK helper)

// TODO: Implement HXScanAllDevicesHelperDelegate methods
/*
- (void)scanHelper:(HXScanAllDevicesHelper *)helper didDiscoverDevice:(HXDeviceModel *)device {
    // Convert SDK device model to Flutter-compatible dictionary
    NSDictionary *devicePayload = @{
        @"deviceId": device.macAddress ?: device.uuid,
        @"name": device.name,
        @"rssi": @(device.rssi),
        @"manufacturerData": device.manufacturerData ? [device.manufacturerData base64EncodedStringWithOptions:0] : @"",
        @"advertisementData": @{
            @"localName": device.localName ?: @"",
        }
    };
    
    [self.eventEmitter emitEvent:@{
        @"type": @"scanResult",
        @"device": devicePayload
    }];
}

- (void)scanHelperDidStopScan:(HXScanAllDevicesHelper *)helper {
    [self stopScan];
}
*/

@end
