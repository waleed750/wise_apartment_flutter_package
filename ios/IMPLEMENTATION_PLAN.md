# iOS Plugin Implementation Plan

## Timeline: 20 Days (4 Weeks)

---

## Week 1: Foundation & Setup (Days 1-5)

### Day 1-2: Project Structure & Skeleton
**Goal**: Set up complete file structure and base classes

- [x] Create all header (.h) and implementation (.m) files
- [x] Define channel names and constants
- [x] Set up WiseApartmentPlugin main class
- [x] Implement FlutterPlugin and FlutterStreamHandler protocols
- [x] Create WAEventEmitter for thread-safe event streaming
- [x] Define WAErrorHandler with error codes

**Deliverables**:
- Plugin skeleton compiles
- Channels registered
- Event emitter tested with mock events

---

### Day 3-4: Manager Classes Infrastructure
**Goal**: Build manager class foundations

- [x] Create WAScanManager skeleton
- [x] Create WAPairManager skeleton
- [x] Create WAWiFiConfigManager skeleton
- [x] Create WABluetoothStateManager skeleton
- [x] Implement basic CBCentralManager integration in WAScanManager
- [x] Add simulation methods for testing without SDK

**Deliverables**:
- All managers instantiate without errors
- Basic CoreBluetooth integration works
- Simulation flows demonstrate event emission

---

### Day 5: Podfile & Dependencies
**Goal**: Configure build system and dependencies

- [ ] Update wise_apartment.podspec with SDK dependencies
- [ ] Test pod installation
- [ ] Configure Info.plist requirements
- [ ] Document setup process in SETUP.md
- [ ] Verify build on physical device

**Deliverables**:
- `pod install` succeeds
- App builds and runs
- Permissions requested properly

---

## Week 2: SDK Integration (Days 6-10)

### Day 6-7: Scan Manager SDK Integration
**Goal**: Replace CoreBluetooth with SDK scanning

- [ ] Import SDK scan helper headers
- [ ] Replace simulation with actual SDK calls
- [ ] Implement SDK delegate methods
- [ ] Map SDK device models to Flutter format
- [ ] Test on physical device with real locks

**Key Tasks**:
```objc
// Replace in WAScanManager.m
#import <HXJBLESDK/HXScanAllDevicesHelper.h>
[self.sdkScanHelper startScanWithTimeout:timeout];

// Implement delegate
- (void)scanHelper:(HXScanAllDevicesHelper *)helper 
  didDiscoverDevice:(HXDeviceModel *)device {
    // Convert and emit
}
```

**Deliverables**:
- Scan finds actual lock devices
- Device payloads match Android format
- Timeout works correctly

---

### Day 8-9: Pair Manager SDK Integration
**Goal**: Implement real pairing flow

- [ ] Import SDK pairing helper
- [ ] Replace simulation with SDK pairing calls
- [ ] Implement progress tracking delegates
- [ ] Extract DNA info from SDK response
- [ ] Handle pairing errors properly

**Key Tasks**:
```objc
// Replace in WAPairManager.m
#import <HXJBLESDK/HXAddBluetoothLockHelper.h>
[self.pairHelper addDeviceWithMac:deviceId 
                        authToken:authToken
                       deviceName:deviceName];

// Map progress events
- (void)addBluetoothLockHelper:(HXAddBluetoothLockHelper *)helper
                      progress:(NSInteger)step { ... }
```

**Deliverables**:
- Successful pairing with physical lock
- DNA info extracted correctly
- Progress events match Android

---

### Day 10: WiFi Config Manager SDK Integration
**Goal**: Implement WiFi provisioning

- [ ] Import SDK WiFi config helper
- [ ] Replace simulation with SDK calls
- [ ] Implement progress/success/failure delegates
- [ ] Add timeout handling
- [ ] Test with WiFi-enabled lock

**Key Tasks**:
```objc
// Replace in WAWiFiConfigManager.m
#import <HXJBLESDK/HXWiFiConfigHelper.h>
[self.wifiConfigHelper configureDevice:deviceId 
                                  ssid:ssid
                              password:password];
```

**Deliverables**:
- Lock connects to WiFi successfully
- Progress tracking accurate
- Timeout triggers properly

---

## Week 3: Channel Integration & Error Handling (Days 11-15)

### Day 11-12: Method Channel Refinement
**Goal**: Ensure all method handlers are robust

- [ ] Add comprehensive parameter validation
- [ ] Implement proper error responses
- [ ] Add logging for debugging
- [ ] Test all method calls from Flutter
- [ ] Handle edge cases (nil params, invalid types)

**Test Cases**:
- Call each method with valid params → success
- Call with missing params → proper error
- Call with invalid types → graceful failure
- Concurrent calls → queued or rejected properly

---

### Day 13-14: Event Channel Polish
**Goal**: Ensure events stream reliably

- [ ] Verify thread safety under load
- [ ] Test event ordering
- [ ] Handle rapid event emission
- [ ] Test event listener attach/detach cycles
- [ ] Verify no memory leaks

**Test Cases**:
- Start scan → receive multiple scanResult events
- Hot restart app → events resume correctly
- Background app → events pause/resume
- Rapid start/stop scan → no crashes

---

### Day 15: Error Mapping & Consistency
**Goal**: Ensure iOS errors match Android format

- [ ] Map all SDK error codes to WAErrorCode
- [ ] Compare error payloads with Android
- [ ] Add user-friendly error messages
- [ ] Document error codes in README

**Deliverables**:
- Error code table matches Android
- Error messages are helpful
- Details field provides debug info

---

## Week 4: Testing & Documentation (Days 16-20)

### Day 16-17: Integration Testing
**Goal**: End-to-end testing with Flutter app

- [ ] Test complete flow: scan → pair → register → configure WiFi
- [ ] Test error scenarios (BT off, permissions denied, timeout)
- [ ] Test app lifecycle (background, foreground, kill)
- [ ] Test hot restart behavior
- [ ] Test on multiple iOS versions (13, 14, 15+)

**Test Scenarios**:
1. Happy path: Full flow succeeds
2. Permission denied: Graceful error
3. Bluetooth off: Proper error message
4. Device out of range: Timeout error
5. Network failure: Server registration fails
6. WiFi wrong password: Config fails

---

### Day 18: Performance & Memory
**Goal**: Optimize and prevent leaks

- [ ] Profile with Instruments (Leaks, Allocations)
- [ ] Check for retain cycles
- [ ] Verify proper cleanup on dispose
- [ ] Test with 100+ scan results
- [ ] Monitor memory during long-running operations

**Metrics**:
- No memory leaks detected
- Memory usage stable over time
- Event emission doesn't accumulate objects

---

### Day 19: Documentation
**Goal**: Complete all documentation

- [ ] Finish SETUP.md with clear steps
- [ ] Document SDK integration points
- [ ] Create troubleshooting guide
- [ ] Add inline code comments
- [ ] Write example Flutter app code

**Deliverables**:
- SETUP.md complete
- API_REFERENCE.md (if needed)
- Example app demonstrating all features

---

### Day 20: Final Review & Handoff
**Goal**: Code review and deployment prep

- [ ] Code review (naming, style, safety)
- [ ] Remove all simulation code (if SDK fully integrated)
- [ ] Verify all TODOs addressed
- [ ] Test pod installation on fresh project
- [ ] Final device testing

**Checklist**:
- [ ] All SDK calls implemented (no simulations)
- [ ] All error codes mapped
- [ ] Documentation complete
- [ ] Example app works
- [ ] No compiler warnings
- [ ] Passes pod lib lint

---

## Critical Success Factors

### Must Have
1. **Thread Safety**: All Flutter callbacks on main thread
2. **Error Consistency**: iOS errors match Android format exactly
3. **Memory Safety**: No leaks or retain cycles
4. **Event Reliability**: Events always reach Flutter
5. **Permissions**: Proper handling of BT/Location permissions

### Nice to Have
1. Background scanning support
2. Multiple concurrent pairing
3. Device caching/persistence
4. SDK error → Flutter error mapping table

### Dependencies & Risks

| Risk | Mitigation |
|------|-----------|
| SDK API differs from Android | Early integration, flag differences |
| Permissions complexity | Test on iOS 13, 14, 15+ early |
| BLE scanning limitations | Clear docs on simulator vs device |
| SDK documentation lacking | Reverse-engineer from Android implementation |
| Memory leaks in SDK | Add wrapper guards, monitor closely |

---

## File Checklist

- [x] `WiseApartmentPlugin.h/.m` - Main plugin
- [x] `WAEventEmitter.h/.m` - Event streaming
- [x] `WAErrorHandler.h/.m` - Error handling
- [x] `WAScanManager.h/.m` - BLE scanning
- [x] `WAPairManager.h/.m` - Device pairing
- [x] `WAWiFiConfigManager.h/.m` - WiFi config
- [x] `WABluetoothStateManager.h/.m` - BT state
- [x] `WADeviceModel.h/.m` - Device model
- [x] `wise_apartment.podspec` - Pod spec
- [x] `SETUP.md` - Setup instructions

**Next Steps**: 
1. Review this plan
2. Integrate actual SDK
3. Follow timeline day-by-day
4. Test continuously on device
