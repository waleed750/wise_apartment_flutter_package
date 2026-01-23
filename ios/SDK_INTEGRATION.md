# SDK Integration Quick Reference

This document lists **all TODO locations** where you need to plug in your actual Smart Lock SDK calls.

---

## 🎯 Integration Checklist

### Phase 1: Imports & Setup

#### wise_apartment.podspec
**Line ~25**: Add SDK dependency

```ruby
# Option 1: CocoaPods
s.dependency 'HXJBLESDK', '~> 2.5.0'

# Option 2: Vendored framework
s.vendored_frameworks = 'Frameworks/HXJBLESDK.framework'
```

---

### Phase 2: WiseApartmentPlugin.m

#### Line ~60: Initialize SDK (handleInitialize method)
```objc
// TODO: Initialize SDK if needed (e.g., set API keys, configure defaults)
// Example: [[HXSDKManager shared] initializeWithKey:@"YOUR_KEY"];
```

#### Line ~155: Server Registration (handleRegisterToServer method)
```objc
// TODO: Call SDK server registration API
// Example: [[HXServerManager shared] registerDevice:deviceId token:token extra:extra completion:^(BOOL success, NSError *error) { ... }];
```

---

### Phase 3: WAScanManager.m

#### Line ~10-12: Import SDK Headers
```objc
// TODO: Import your actual SDK headers
#import <HXJBLESDK/HXScanAllDevicesHelper.h>
#import <HXJBLESDK/HXScanAllDevicesHelperDelegate.h>
```

#### Line ~20: Add Delegate Protocol
```objc
@interface WAScanManager () <CBCentralManagerDelegate, HXScanAllDevicesHelperDelegate>
```

#### Line ~29-30: SDK Helper Property
```objc
// TODO: Replace with actual SDK helper
@property (nonatomic, strong) HXScanAllDevicesHelper *sdkScanHelper;
```

#### Line ~40-42: Initialize SDK Helper
```objc
// TODO: Initialize SDK scan helper if needed
_sdkScanHelper = [[HXScanAllDevicesHelper alloc] init];
_sdkScanHelper.delegate = self;
```

#### Line ~75-78: Start SDK Scan
```objc
// === OPTION 2: Using SDK scan helper (uncomment when SDK is available) ===
// TODO: Call SDK scan method
[self.sdkScanHelper startScanWithTimeout:timeout];
```

#### Line ~97-98: Stop SDK Scan
```objc
// TODO: Stop SDK scan helper if used
[self.sdkScanHelper stopScan];
```

#### Line ~179-202: SDK Delegate Implementation
```objc
// TODO: Implement HXScanAllDevicesHelperDelegate methods
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
```

---

### Phase 4: WAPairManager.m

#### Line ~10-11: Import SDK Headers
```objc
// TODO: Import SDK pairing helper
#import <HXJBLESDK/HXAddBluetoothLockHelper.h>
```

#### Line ~13: Add Delegate Protocol
```objc
@interface WAPairManager () <HXAddBluetoothLockHelperDelegate>
```

#### Line ~22-23: SDK Helper Property
```objc
// TODO: SDK helper instance
@property (nonatomic, strong) HXAddBluetoothLockHelper *pairHelper;
```

#### Line ~33-35: Initialize SDK Helper
```objc
// TODO: Initialize SDK pairing helper
_pairHelper = [[HXAddBluetoothLockHelper alloc] init];
_pairHelper.delegate = self;
```

#### Line ~67-78: SDK Pairing Call
```objc
// TODO: Replace with actual SDK pairing call
// Example SDK integration:
[self.pairHelper addDeviceWithMac:deviceId
                        authToken:authToken
                       deviceName:deviceName
                          success:^(HXDeviceInfo *deviceInfo) {
    [self handlePairingSuccess:deviceInfo];
} failure:^(NSError *error) {
    [self handlePairingFailure:error];
}];
```

#### Line ~88-89: Cancel SDK Pairing
```objc
// TODO: Cancel SDK pairing operation
[self.pairHelper cancelPairing];
```

#### Line ~217-270: SDK Delegate Implementation
```objc
// TODO: Implement SDK delegate methods
- (void)addBluetoothLockHelper:(HXAddBluetoothLockHelper *)helper
                      progress:(NSInteger)step
                       message:(NSString *)message
                       percent:(NSInteger)percent {
    
    NSString *stepName = [self stepNameForSDKStep:step];
    [self emitPairingProgress:stepName message:message percent:percent];
}

- (void)addBluetoothLockHelper:(HXAddBluetoothLockHelper *)helper
                didSucceedWithDevice:(HXDeviceInfo *)deviceInfo {
    
    NSDictionary *info = @{
        @"device": @{
            @"deviceId": deviceInfo.macAddress,
            @"name": deviceInfo.deviceName,
            @"type": deviceInfo.deviceType
        },
        @"dnaInfo": @{
            @"dnaId": deviceInfo.dnaId,
            @"lockType": deviceInfo.lockType,
            @"firmwareVersion": deviceInfo.firmwareVersion
        }
    };
    
    [self handlePairingSuccess:info];
}

- (void)addBluetoothLockHelper:(HXAddBluetoothLockHelper *)helper
                didFailWithError:(NSError *)error {
    [self handlePairingFailure:error];
}

- (NSString *)stepNameForSDKStep:(NSInteger)step {
    // Map SDK step constants to Flutter-friendly names
    switch (step) {
        case HXPairStepConnecting: return @"connecting";
        case HXPairStepAuthenticating: return @"authenticating";
        case HXPairStepPairing: return @"pairing";
        default: return @"processing";
    }
}
```

---

### Phase 5: WAWiFiConfigManager.m

#### Line ~10-11: Import SDK Headers
```objc
// TODO: Import SDK WiFi config helper
#import <HXJBLESDK/HXWiFiConfigHelper.h>
```

#### Line ~13: Add Delegate Protocol
```objc
@interface WAWiFiConfigManager () <HXWiFiConfigHelperDelegate>
```

#### Line ~22-23: SDK Helper Property
```objc
// TODO: SDK helper instance
@property (nonatomic, strong) HXWiFiConfigHelper *wifiConfigHelper;
```

#### Line ~33-35: Initialize SDK Helper
```objc
// TODO: Initialize SDK WiFi config helper
_wifiConfigHelper = [[HXWiFiConfigHelper alloc] init];
_wifiConfigHelper.delegate = self;
```

#### Line ~75-86: SDK WiFi Config Call
```objc
// TODO: Replace with actual SDK WiFi config call
[self.wifiConfigHelper configureDevice:deviceId
                                  ssid:ssid
                              password:password
                              wifiType:wifiType
                               timeout:timeout
                               success:^{
    [self handleConfigSuccess:deviceId];
} failure:^(NSError *error) {
    [self handleConfigFailure:error];
}];
```

#### Line ~95-96: Cancel SDK WiFi Config
```objc
// TODO: Cancel SDK WiFi config operation
[self.wifiConfigHelper cancelConfiguration];
```

#### Line ~194-212: SDK Delegate Implementation
```objc
// TODO: Implement SDK delegate methods
- (void)wifiConfigHelper:(HXWiFiConfigHelper *)helper
                progress:(NSString *)step
                 percent:(NSInteger)percent {
    [self emitWiFiProgress:step percent:percent];
}

- (void)wifiConfigHelper:(HXWiFiConfigHelper *)helper
       didSucceedForDevice:(NSString *)deviceId {
    [self handleConfigSuccess:deviceId];
}

- (void)wifiConfigHelper:(HXWiFiConfigHelper *)helper
        didFailWithError:(NSError *)error {
    [self handleConfigFailure:error];
}
```

---

## 🔍 How to Find TODOs

Search for these patterns in the codebase:

```bash
# From ios/ directory
grep -r "TODO:" Classes/
```

Or in Xcode:
1. Open `ios/Runner.xcworkspace`
2. Press `Cmd + Shift + F`
3. Search for "TODO:"

---

## ⚡ Quick Integration Steps

### 1. Import Phase
- [ ] Add all SDK headers to manager files
- [ ] Update interface declarations with SDK delegate protocols

### 2. Property Phase
- [ ] Declare SDK helper properties in each manager
- [ ] Initialize helpers in `init` methods

### 3. Method Phase
- [ ] Replace simulation code with SDK method calls
- [ ] Pass correct parameters from Flutter → SDK

### 4. Delegate Phase
- [ ] Implement all SDK delegate methods
- [ ] Convert SDK responses to Flutter format
- [ ] Call event emitter with proper event types

### 5. Error Mapping Phase
- [ ] Map SDK error codes to WAErrorCode
- [ ] Ensure error messages are user-friendly

### 6. Testing Phase
- [ ] Remove simulation code
- [ ] Test each flow on physical device
- [ ] Verify events match Android implementation

---

## 📋 SDK Method Signatures (Expected)

Based on HXJBLESDK Android patterns, your iOS SDK likely has these signatures:

### Scanning
```objc
@interface HXScanAllDevicesHelper : NSObject
@property (weak, nonatomic) id<HXScanAllDevicesHelperDelegate> delegate;
- (void)startScanWithTimeout:(NSTimeInterval)timeout;
- (void)stopScan;
@end

@protocol HXScanAllDevicesHelperDelegate <NSObject>
- (void)scanHelper:(HXScanAllDevicesHelper *)helper didDiscoverDevice:(HXDeviceModel *)device;
- (void)scanHelperDidStopScan:(HXScanAllDevicesHelper *)helper;
@end
```

### Pairing
```objc
@interface HXAddBluetoothLockHelper : NSObject
@property (weak, nonatomic) id<HXAddBluetoothLockHelperDelegate> delegate;
- (void)addDeviceWithMac:(NSString *)mac
               authToken:(NSString *)token
              deviceName:(NSString *)name
                 success:(void(^)(HXDeviceInfo *info))success
                 failure:(void(^)(NSError *error))failure;
- (void)cancelPairing;
@end

@protocol HXAddBluetoothLockHelperDelegate <NSObject>
- (void)addBluetoothLockHelper:(HXAddBluetoothLockHelper *)helper
                      progress:(NSInteger)step
                       message:(NSString *)message
                       percent:(NSInteger)percent;
@end
```

### WiFi Config
```objc
@interface HXWiFiConfigHelper : NSObject
@property (weak, nonatomic) id<HXWiFiConfigHelperDelegate> delegate;
- (void)configureDevice:(NSString *)deviceId
                   ssid:(NSString *)ssid
               password:(NSString *)password
               wifiType:(NSInteger)type
                timeout:(NSTimeInterval)timeout
                success:(void(^)(void))success
                failure:(void(^)(NSError *error))failure;
@end
```

**If signatures differ**: Adjust the implementation accordingly, but keep the Flutter interface unchanged.

---

## ✅ Verification

After SDK integration, verify:

1. **Compilation**: Xcode builds without errors
2. **Scanning**: Real devices appear in scan results
3. **Pairing**: Can successfully pair with physical lock
4. **WiFi Config**: Lock connects to WiFi network
5. **Events**: All events reach Flutter correctly
6. **Errors**: SDK errors map to Flutter error codes
7. **Cleanup**: No memory leaks or crashes

---

## 🆘 Troubleshooting SDK Integration

### "Framework not found"
- Check `wise_apartment.podspec` has correct dependency
- Run `pod install` again
- Verify framework is in `Frameworks/` if vendored

### "Protocol not found"
- Ensure all SDK headers are imported
- Check SDK header search paths in Xcode

### "Delegate methods not called"
- Verify `delegate` property is set: `helper.delegate = self;`
- Check delegate protocol is in `@interface` declaration
- Ensure SDK is using correct thread (may need dispatch_async to main)

### "Events not reaching Flutter"
- Check `[self.eventEmitter emitEvent:...]` is called
- Verify event has `type` key
- Check Flutter is listening: `_events.receiveBroadcastStream().listen(...)`

---

**Next**: Start SDK integration following the [IMPLEMENTATION_PLAN.md](IMPLEMENTATION_PLAN.md) timeline!
