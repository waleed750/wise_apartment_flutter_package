# Plan: Gather All Unimplemented Features → wise_apartment Plugin + New Example UI

## Context

The `wise_apartment` Flutter plugin wraps the HXJ BLE SDK for both Android and iOS. The Android demo app (`app/`) and iOS demo app (`ios_wise_apartment-main/`) each contain features that are not yet surfaced through the plugin. Additionally, the current example app UI is minimal. This plan closes both gaps: completing the plugin API surface and building a full-featured example app UI.

---

## Gap Analysis: What's Missing from wise_apartment

### Missing Plugin Methods

| Feature | Android Demo Source | iOS Demo Source | Plugin Status |
|---|---|---|---|
| **Firmware Upgrade (HXJBLE API)** | `FirmwareUpgradeActivity.java` | `HXBLEUpgradeVC.m` | ❌ Missing |
| **OAD / Nordic DFU Upgrade** | `OadListActivity`, `OadLoadingActivity`, `DfuService`, `HxDfuActivity` | — | ❌ Missing |
| **BLE Card Commands** | `CardCmd.java` + `NewFeatureFragment.java` | — | ❌ Missing |
| **Lock Push Event Stream** | `SyncLogFragment` (event constants) | `HXPushEventHelper.m` + `HXPushEventVC.m` | ❌ Missing EventChannel |
| **Firmware upgrade progress stream** | OAD progress callbacks | `HXBLEUpgradeVC` progress | ❌ Missing |

### What's Already in the Plugin (both Android ✅ iOS ✅)
- `initBleClient`, `startScan`, `stopScan`, `openLock`, `closeLock`, `disconnect`
- `getDna`, `addDevice`, `deleteLock`, `getNBIoTInfo`, `getCat1Info`
- `addLockKey`, `deleteLockKey`, `modifyLockKey`, `changeLockKeyPwd`, `syncLockKey`
- `syncLockRecords`, `syncLockRecordsPage`, `syncLockTime`
- `getSysParam`, `setSysParam`, `enableKeyById/ByType/ByUserId`
- `registerWifi`, `exitCmd`, `clearSdkState`
- Big data key (fingerprint/face): `AddBigDataKeyHelper`
- EventChannels: `syncLockKeyStream`, `syncLockRecordsStream`, `addLockKeyStream`, `getSysParamStream`, `wifiRegistrationStream`

---

## Phase 1: Implement Missing Plugin Features

### 1A. Firmware Upgrade (HXJBLE API)

**Android** — `FirmwareUpgradeActivity.java` uses `loadLockAuthAction()` + a firmware-upgrade helper from the HXJ library.

- Add method: `checkFirmwareVersion(Map auth)` → returns current lock firmware version
- Add method: `startFirmwareUpgrade(Map auth, String filePath)` → begins OTA upgrade
- Add EventChannel: `firmwareUpgradeStream` — emits `{progress: int, status: String}` events
- Files to modify: `WiseApartmentPlugin.java`, new `FirmwareUpgradeManager.java` in `utils/`
- iOS: Mirror using `HXBLEUpgradeHelper.h` / `HXBLEUpgradeHelper` in `WiseApartmentPlugin.m`
- Dart: Add `checkFirmwareVersion()`, `startFirmwareUpgrade()`, `firmwareUpgradeStream` to `wise_apartment.dart`

### 1B. OAD / Nordic DFU Upgrade (Android only)

Android demo uses `dfu_release.aar` + `bleoad-release.aar` for OAD-style firmware flashing (different flow from HXJBLE API upgrade).

- Add method: `startOadUpgrade(Map auth, String filePath)` → Android-only
- Add EventChannel: `oadUpgradeStream` — progress events `{percent: int, phase: String}`
- Files to modify: `WiseApartmentPlugin.java`, new `OadUpgradeManager.java` in `utils/`
- iOS: Return `NOT_SUPPORTED` (OAD is Android-only in the SDK)
- Dart: Add with `@visibleForTesting` platform guard; document as Android-only

### 1C. BLE Card Commands (Android, `CardCmd.java` + `NewFeatureFragment.java`)

The SDK supports writing commands to BLE-enabled smart cards. Four card operations:

- Add method: `bleCardCommand(Map auth, String cardCmd, Map params)` where `cardCmd` is one of `makeTimeCard | makeClearCard | makeSetCard | makeSysSettingCard`
- Android: Route to `CardCmd.java` static methods already present in the demo
- iOS: Return `NOT_SUPPORTED` unless iOS SDK has a matching API
- Files: `WiseApartmentPlugin.java`, new `BleCardManager.java`, Dart side

### 1D. Lock Push Event Stream

Android: `JQBLEDefines.h` + `SyncLogFragment` handle real-time events from the lock (unlock, add-key, delete-key, alarm, etc.).  
iOS: `HXPushEventHelper.m` + `HXPushEventVC.m` handle the same.

- Add EventChannel: `lockPushEventStream` — emits event payloads as `Map<String, dynamic>` matching the event type constants in `JQBLEDefines.h`
- Android: Wire into the existing `MyBleClient.java` callback dispatch
- iOS: Wire into the `HXPushEventHelper` delegate
- Dart: Expose as `Stream<Map<String, dynamic>> lockPushEventStream`

---

## Phase 2: Local Lock Storage

When a lock is successfully added via `addDevice` + `getDna`, the example app must persist the lock's data locally so it survives app restarts.

### What to Store Per Lock

```dart
class LocalLock {
  final String mac;           // BLE MAC address — primary key
  final String name;          // User-assigned friendly name (e.g. "Front Door")
  final String dna;           // Raw DNA string returned by getDna()
  final String aesKey;        // AES128 key from DNA (parsed)
  final String authCode;      // Auth code from DNA (parsed)
  final int lockType;         // Lock hardware type from addDevice response
  final DateTime addedAt;     // When it was paired
}
```

The DNA is the critical auth credential — without it the app cannot issue any BLE commands after restart. Both the Android `Lock.java` entity and iOS `HXCoreDataStackHelper.m` persist exactly these fields.

### Storage Approach

Use `shared_preferences` (JSON-encoded list) — no database dependency needed for the example app. A single `LockRepository` class owns all read/write.

**Add flow (triggered after `addDevice` succeeds):**
1. Prompt user to enter a friendly name (bottom sheet dialog)
2. Call `getDna(auth)` to retrieve DNA
3. Parse DNA response → extract `aesKey` + `authCode`
4. Construct `LocalLock` and call `LockRepository.save(lock)`
5. Navigate to `LockDetailScreen`

**On delete:** call `deleteLock(auth)` on the SDK, then `LockRepository.delete(mac)`.

### Files

```
wise_apartment/example/lib/
└── features/
    └── lock_storage/
        ├── local_lock.dart          (model — fields above)
        └── lock_repository.dart     (save / load / delete via shared_preferences)
```

---

## Phase 3: New Example App UI

Build a full-featured example app in `wise_apartment/example/lib/` using **Material 3**. The structure mirrors both SDK demo apps' screens and is organized by **feature folder** — each feature contains its own screen(s), widgets, and any local logic.

### Screen Map

```
HomeScreen
├── Add Device Flow          → feature: add_device
│   ├── ScanScreen
│   └── ConfirmAddScreen
└── LockDetailScreen         → feature: lock_detail
    ├── UnlockButton + CloseButton + SyncTimeButton
    ├── Key Management       → feature: key_management
    │   ├── KeyListScreen
    │   ├── AddKeyScreen (password / fingerprint / card / remote / face)
    │   └── KeyDetailScreen (modify time, enable/disable, delete, change pwd)
    ├── Operation Records    → feature: operation_records
    │   └── RecordsScreen (paginated list with type icons)
    ├── System Parameters    → feature: system_parameters
    │   └── SysParamScreen (grouped switches + inputs)
    ├── Push Events          → feature: push_events
    │   └── PushEventsScreen (real-time stream feed)
    ├── Firmware Upgrade     → feature: firmware_upgrade
    │   └── FirmwareUpgradeScreen (progress bar + file picker)
    ├── WiFi Config          → feature: wifi_config
    │   └── WifiRegisterScreen (SSID + password form)
    └── NB-IoT / CAT-1 Info → feature: network_info
        └── NetworkInfoScreen (read-only display)
```

### Feature Folder Structure

Every feature is self-contained. Shared widgets and infrastructure live in `core/`.

```
wise_apartment/example/lib/
├── main.dart                          (update — MaterialApp.router + theme)
├── core/
│   ├── router.dart                    (go_router config — all routes)
│   ├── theme.dart                     (M3 color scheme)
│   └── widgets/
│       ├── progress_overlay.dart      (reusable loading + progress widget)
│       └── section_header.dart        (grouped list section label)
├── features/
│   ├── lock_storage/                  (see Phase 2 above)
│   │   ├── local_lock.dart
│   │   └── lock_repository.dart
│   ├── home/
│   │   ├── home_screen.dart
│   │   └── widgets/
│   │       └── lock_card.dart         (name, MAC, status badge, quick-unlock FAB)
│   ├── add_device/
│   │   ├── scan_screen.dart
│   │   ├── confirm_add_screen.dart    (enter name, shows DNA result)
│   │   └── widgets/
│   │       └── scan_result_tile.dart
│   ├── lock_detail/
│   │   ├── lock_detail_screen.dart
│   │   └── widgets/
│   │       └── action_grid.dart       (grid of feature buttons)
│   ├── key_management/
│   │   ├── key_list_screen.dart
│   │   ├── add_key_screen.dart
│   │   ├── key_detail_screen.dart
│   │   └── widgets/
│   │       └── key_type_badge.dart    (color-coded chip per key type)
│   ├── operation_records/
│   │   ├── records_screen.dart
│   │   └── widgets/
│   │       └── record_tile.dart
│   ├── system_parameters/
│   │   ├── sys_param_screen.dart
│   │   └── widgets/
│   │       └── param_switch_tile.dart
│   ├── push_events/
│   │   ├── push_events_screen.dart    (StreamBuilder on lockPushEventStream)
│   │   └── widgets/
│   │       └── event_tile.dart
│   ├── firmware_upgrade/
│   │   ├── firmware_upgrade_screen.dart
│   │   └── widgets/
│   │       └── upgrade_progress_card.dart
│   ├── wifi_config/
│   │   └── wifi_register_screen.dart
│   └── network_info/
│       └── network_info_screen.dart
```

### UI Design Approach

- **Material 3** components throughout (CardWidget, NavigationBar, FilledButton, SegmentedButton)
- **Color scheme**: Smart-home palette — deep blue primary (`#1E3A5F`) with amber accent (`#F5A623`)
- **Lock card** on HomeScreen: shows friendly name, MAC, connection status badge, quick-unlock FAB
- **Stream-driven screens**: RecordsScreen, PushEventsScreen, FirmwareUpgradeScreen use `StreamBuilder`
- **Navigation**: `go_router` for deep-linkable routes; lock identified by MAC in route path (`/lock/:mac/...`)

### Dependencies to Add to `example/pubspec.yaml`

- `go_router: ^14.x`
- `shared_preferences: ^2.x` (lock storage)

---

## Verification

1. `flutter analyze` in `wise_apartment/` — zero warnings
2. Add a lock → verify DNA + name persisted in `shared_preferences`, survives hot restart
3. Restart app → home screen shows saved locks loaded from `LockRepository`
4. Delete a lock → removed from storage and list
5. Run example app on Android with physical BLE lock: test every screen/feature path
6. Run example app on iOS simulator (scan/UI) + physical device (BLE ops)
7. Test firmware upgrade screen shows progress stream correctly
8. Test push events screen updates in real-time when lock triggers events
9. Confirm OAD upgrade method returns `NOT_SUPPORTED` gracefully on iOS
