# 📋 Android_HXJBLESDK → Flutter Plugin Implementation Plan

**Project:** wise_apartment Flutter Plugin  
**Duration:** 4 Weeks (160 hours)  
**Start Date:** _________________  
**Target Completion:** _________________  

---

## 📊 Current State Analysis

| Component | Status | Notes |
|-----------|--------|-------|
| **Flutter Plugin Structure** | ✅ Exists | `wise_apartment/` with proper `pubspec.yaml` |
| **Android MethodChannel** | 🟡 Partially Done | 14 methods mapped, 5 manager classes |
| **iOS Implementation** | ❌ Stub Only | Returns `UNAVAILABLE` for all BLE methods |
| **Example App** | ✅ Basic | Scan + OpenLock UI exists |
| **EventChannel (Streams)** | ❌ Missing | No real-time scan/status updates |

---

## 🔍 SDK API Surface (Current Coverage)

| Method | Android | iOS | Priority |
|--------|---------|-----|----------|
| `initBleClient` | ✅ | ❌ | P0 |
| `startScan` | ✅ | ❌ | P0 |
| `stopScan` | ✅ | ❌ | P0 |
| `openLock` | ✅ | ❌ | P0 |
| `closeLock` | ✅ | ❌ | P0 |
| `deleteLock` | ✅ | ❌ | P1 |
| `disconnect` | ✅ | ❌ | P0 |
| `getDna` | ✅ | ❌ | P1 |
| `getNBIoTInfo` | ✅ | ❌ | P2 |
| `getCat1Info` | ✅ | ❌ | P2 |
| `setKeyExpirationAlarmTime` | ✅ | ❌ | P1 |
| `syncLockRecords` | ✅ | ❌ | P1 |
| `addDevice` | 🟡 Partial | ❌ | P1 |
| `clearSdkState` | ✅ | ✅ | P2 |

---

# 📆 Week 1: Android Hardening + EventChannel Architecture

## Day 1-2: Audit & Gap Analysis (16 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Document all `HxjBleClient` public methods vs. plugin coverage | 4h | | ☐ |
| Trace callback flows: `LinkCallBack`, `FunCallback`, `HxjScanCallback` | 4h | | ☐ |
| Identify missing Android 12+ permissions (`BLUETOOTH_SCAN`, `BLUETOOTH_CONNECT`) | 2h | | ☐ |
| Review threading: main thread vs. background callbacks | 2h | | ☐ |
| Create SDK method → Dart method mapping spreadsheet | 4h | | ☐ |

**Deliverables:**
- [ ] Gap analysis spreadsheet
- [ ] Callback mapping document
- [ ] Permission matrix

## Day 3-4: Implement EventChannel for Real-time Streams (16 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Create `BleScanEventChannel.java` - stream scan results | 6h | | ☐ |
| Create `BleConnectionEventChannel.java` - connection state changes | 4h | | ☐ |
| Update Dart side: add `Stream<BleDevice> scanStream` | 3h | | ☐ |
| Update Dart side: add `Stream<ConnectionState> connectionStream` | 3h | | ☐ |

**Files to Create:**
```
android/src/main/java/com/example/wise_apartment/
├── channels/
│   ├── BleScanEventChannel.java
│   └── BleConnectionEventChannel.java
lib/
├── src/
│   ├── ble_device.dart
│   └── connection_state.dart
```

## Day 5: Error Code Standardization (8 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Define unified error enum in Dart: `WiseApartmentErrorCode` | 2h | | ☐ |
| Map all native `response.code()` values to enum | 3h | | ☐ |
| Replace string errors with structured `FlutterError` in all managers | 3h | | ☐ |

**Error Codes to Define:**
```dart
enum WiseApartmentErrorCode {
  permissionDenied,      // Missing BLE/Location permissions
  bluetoothDisabled,     // Bluetooth adapter is off
  deviceNotFound,        // Cannot find device by MAC
  connectionFailed,      // Failed to connect to device
  authenticationFailed,  // Invalid auth credentials
  operationFailed,       // Command sent but failed
  timeout,               // Operation timed out
  unknown,               // Unexpected error
}
```

### Week 1 Checklist
- [ ] EventChannel for scan stream working
- [ ] EventChannel for connection state working
- [ ] Error codes standardized
- [ ] No regressions on existing methods
- [ ] Unit tests for new Dart models

---

# 📆 Week 2: Android Completion + Activity Lifecycle

## Day 1-2: Permission Handling & Activity Integration (16 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Implement `ActivityAware` interface in plugin | 4h | | ☐ |
| Add `requestBlePermissions()` method | 4h | | ☐ |
| Handle `onActivityResult` for Bluetooth enable prompt | 4h | | ☐ |
| Add `checkBlePermissions()` → returns `Map<String, bool>` | 2h | | ☐ |
| Test on Android 10, 11, 12, 13, 14 | 2h | | ☐ |

**Code Changes:**
```java
// WiseApartmentPlugin.java
public class WiseApartmentPlugin implements 
    FlutterPlugin, 
    MethodCallHandler,
    ActivityAware,           // ADD
    PluginRegistry.ActivityResultListener {  // ADD
    
    private ActivityPluginBinding activityBinding;
    
    @Override
    public void onAttachedToActivity(ActivityPluginBinding binding) {
        this.activityBinding = binding;
        binding.addActivityResultListener(this);
    }
    // ... implement other ActivityAware methods
}
```

## Day 3-4: Background Handling & Edge Cases (16 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Test scan behavior when app is backgrounded | 2h | | ☐ |
| Add foreground service support for long operations (optional) | 4h | | ☐ |
| Handle Bluetooth adapter on/off during operations | 3h | | ☐ |
| Add defensive null checks in all 5 manager classes | 3h | | ☐ |
| Add `@UiThread` / `@WorkerThread` annotations | 2h | | ☐ |
| Handle rapid connect/disconnect cycles | 2h | | ☐ |

## Day 5: Example App Polish & Validation (8 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Update example app with permission request flow | 3h | | ☐ |
| Add connection state indicator in UI | 2h | | ☐ |
| Create test matrix document | 1h | | ☐ |
| Run full validation on 2+ physical devices | 2h | | ☐ |

**Test Matrix:**

| Device | Android Ver | API | BLE Ver | Test Result |
|--------|-------------|-----|---------|-------------|
| Pixel 4a | 12 | 31 | 5.0 | ☐ |
| Samsung S21 | 13 | 33 | 5.2 | ☐ |
| Xiaomi Note 10 | 11 | 30 | 5.0 | ☐ |
| _Add more..._ | | | | |

### Week 2 Checklist
- [ ] Permission flow works on Android 10-14
- [ ] `ActivityAware` fully implemented
- [ ] Example app demonstrates all methods
- [ ] Tested on 2+ physical Android devices
- [ ] Background/foreground transitions handled

---

# 📆 Week 3: iOS Native Implementation (CoreBluetooth)

## Day 1-2: CoreBluetooth Foundation (16 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Create `BleCentralManager.swift` - CBCentralManager wrapper | 6h | | ☐ |
| Create `BlePeripheralHandler.swift` - device connection handler | 4h | | ☐ |
| Implement service/characteristic discovery | 4h | | ☐ |
| Add `Info.plist` keys for Bluetooth | 1h | | ☐ |
| Handle CBCentralManager authorization states | 1h | | ☐ |

**Files to Create:**
```
ios/Classes/
├── WiseApartmentPlugin.swift (update)
├── BleCentralManager.swift (new)
├── BlePeripheralHandler.swift (new)
├── HxjLockProtocol.swift (new)
└── Models/
    ├── BleDevice.swift
    └── LockCommand.swift
```

**Info.plist Additions:**
```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to communicate with smart locks.</string>
<key>NSBluetoothPeripheralUsageDescription</key>
<string>This app uses Bluetooth to communicate with smart locks.</string>
<key>UIBackgroundModes</key>
<array>
    <string>bluetooth-central</string>
</array>
```

## Day 3: Method Parity Implementation - Core (8 hours)

| Method | Est. Hours | Owner | Status |
|--------|------------|-------|--------|
| `initBleClient` → Initialize CBCentralManager | 1h | | ☐ |
| `startScan` → `scanForPeripherals(withServices:)` | 2h | | ☐ |
| `stopScan` → `stopScan()` | 0.5h | | ☐ |
| `disconnect` → `cancelPeripheralConnection` | 0.5h | | ☐ |
| `openLock` → Connect + Write characteristic | 3h | | ☐ |
| `closeLock` → Write characteristic | 1h | | ☐ |

## Day 4: Method Parity Implementation - Advanced (8 hours)

| Method | Est. Hours | Owner | Status |
|--------|------------|-------|--------|
| `deleteLock` | 1.5h | | ☐ |
| `getDna` | 1.5h | | ☐ |
| `syncLockRecords` | 2h | | ☐ |
| `setKeyExpirationAlarmTime` | 1h | | ☐ |
| Implement EventChannels for iOS | 2h | | ☐ |

## Day 5: iOS Testing & Edge Cases (8 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Test on physical iPhone with BLE lock | 4h | | ☐ |
| Handle CBCentralManager states (poweredOff, unauthorized) | 2h | | ☐ |
| Test app backgrounding during BLE operations | 1h | | ☐ |
| Test app termination during connection | 1h | | ☐ |

**iOS Test Matrix:**

| Device | iOS Ver | Test Result |
|--------|---------|-------------|
| iPhone 12 | 16.x | ☐ |
| iPhone SE | 15.x | ☐ |
| iPad Pro | 17.x | ☐ |

### Week 3 Checklist
- [ ] All 14 methods implemented in iOS
- [ ] EventChannels working on iOS
- [ ] Tested on 1+ physical iOS device
- [ ] CBCentralManager states handled gracefully
- [ ] Background BLE working

---

# 📆 Week 4: Unification, Documentation & Release Prep

## Day 1-2: Cross-Platform Parity Audit (16 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Create Android vs iOS behavior comparison table | 3h | | ☐ |
| Unify error codes: same `FlutterError` codes both platforms | 4h | | ☐ |
| Normalize response JSON structures | 3h | | ☐ |
| Fix platform-specific quirks | 4h | | ☐ |
| Create platform behavior documentation | 2h | | ☐ |

**Parity Checklist:**

| Behavior | Android | iOS | Same? |
|----------|---------|-----|-------|
| Scan returns device list | ✓ | ☐ | ☐ |
| Error code format | ✓ | ☐ | ☐ |
| Connection timeout value | ✓ | ☐ | ☐ |
| Auth parameter names | ✓ | ☐ | ☐ |
| Response JSON structure | ✓ | ☐ | ☐ |

## Day 3: Documentation (8 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Update `README.md` with iOS setup | 2h | | ☐ |
| Add API documentation with dartdoc comments | 3h | | ☐ |
| Create `CHANGELOG.md` v1.0.0 | 1h | | ☐ |
| Add troubleshooting section | 1h | | ☐ |
| Create migration guide (if updating from older version) | 1h | | ☐ |

## Day 4: Example App Finalization (8 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Polish example app UI (Material 3) | 3h | | ☐ |
| Add all methods to example with proper UI | 3h | | ☐ |
| Add loading states / error handling in UI | 1h | | ☐ |
| Test example app on both platforms | 1h | | ☐ |

## Day 5: Release Readiness (8 hours)

| Task | Est. Hours | Owner | Status |
|------|------------|-------|--------|
| Run `flutter analyze` - fix all warnings | 2h | | ☐ |
| Run `dart format .` on all Dart files | 0.5h | | ☐ |
| Validate `pubspec.yaml` for pub.dev | 1h | | ☐ |
| Final integration test: Android + iOS same app | 2h | | ☐ |
| Tag version 1.0.0 in git | 0.5h | | ☐ |
| Write release notes | 1h | | ☐ |
| Team demo / handoff meeting | 1h | | ☐ |

### Week 4 Checklist
- [ ] README.md complete with all setup steps
- [ ] API documentation complete
- [ ] Example app demonstrates all features
- [ ] Zero analyzer warnings
- [ ] Tested on Android + iOS with same Flutter app
- [ ] Version 1.0.0 tagged
- [ ] CHANGELOG.md created

---

# ⚠️ Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| **HXJ BLE protocol undocumented for iOS** | 🔴 High | 🔴 High | Reverse-engineer from Android SDK; request protocol spec from vendor ASAP |
| **iOS permission rejections in App Store** | 🟡 Medium | 🔴 High | Add clear usage descriptions; test on TestFlight before submission |
| **Android 14 BLE behavioral changes** | 🟡 Medium | 🟡 Medium | Test on Android 14 device early; monitor release notes |
| **Callback threading causing ANRs** | 🟡 Medium | 🟡 Medium | Use `@WorkerThread` annotations; test with StrictMode |
| **EventChannel memory leaks** | 🟢 Low | 🟡 Medium | Implement proper `dispose()` in Dart; test with DevTools |
| **Physical BLE lock unavailable** | 🟡 Medium | 🔴 High | Secure hardware access BEFORE Week 3; have backup device |
| **iOS CoreBluetooth quirks** | 🟡 Medium | 🟡 Medium | Research known issues; build in extra iOS buffer time |

---

# ✅ Final Definition of Done

```
MUST HAVE (v1.0.0 Release Criteria):
────────────────────────────────────
☐ All 14 SDK methods callable from Flutter
☐ Android: Tested on API 26+ (2 devices minimum)
☐ iOS: Tested on iOS 13+ (1 device minimum)  
☐ Unified error codes (same Dart exceptions both platforms)
☐ README with installation + setup + usage
☐ Example app runs on both platforms
☐ Zero `flutter analyze` errors or warnings
☐ CHANGELOG.md with v1.0.0 entry

SHOULD HAVE (v1.1.0):
────────────────────────────────────
☐ EventChannel streams for scan results
☐ EventChannel streams for connection state
☐ Comprehensive dartdoc API comments
☐ Unit tests for Dart code (>70% coverage)

NICE TO HAVE (v1.2.0+):
────────────────────────────────────
☐ Integration tests
☐ CI/CD pipeline (GitHub Actions)
☐ pub.dev publication
☐ Background execution support (iOS)
```

---

# 📈 Time Allocation Summary

| Week | Focus Area | Hours | % |
|------|------------|-------|---|
| Week 1 | Android Hardening + EventChannels | 40h | 25% |
| Week 2 | Android Completion + Lifecycle | 40h | 25% |
| Week 3 | iOS Implementation | 40h | 25% |
| Week 4 | Polish + Documentation + Release | 40h | 25% |
| **Total** | | **160h** | 100% |

---

# 📝 Daily Standup Template

```
Date: ___________

Yesterday:
- [ ] Completed: _____________
- [ ] Blocked by: _____________

Today:
- [ ] Focus: _____________
- [ ] Dependencies: _____________

Blockers:
- _____________
```

---

# 📞 Key Contacts

| Role | Name | Contact |
|------|------|---------|
| Project Lead | | |
| Android Developer | | |
| iOS Developer | | |
| QA Engineer | | |
| HXJ Vendor Contact | | |

---

**Document Version:** 1.0  
**Created:** December 24, 2024  
**Last Updated:** December 24, 2024
