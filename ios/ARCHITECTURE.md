# Architecture Overview

```
┌─────────────────────────────────────────────────────────────────────────┐
│                           FLUTTER APP LAYER                             │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │  • UI (Scan, Pair, Configure)                                     │ │
│  │  • State Management                                               │ │
│  │  • Business Logic                                                 │ │
│  └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
                                    │
                    ┌───────────────┴───────────────┐
                    ↓                               ↓
        ┌─────────────────────┐       ┌─────────────────────┐
        │   MethodChannel     │       │   EventChannel      │
        │ wise_apartment/     │       │ wise_apartment/     │
        │     methods         │       │     events          │
        └─────────────────────┘       └─────────────────────┘
                    │                               ↑
                    ↓                               │
┌─────────────────────────────────────────────────────────────────────────┐
│                        iOS PLUGIN LAYER (Objective-C)                   │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │              WiseApartmentPlugin.m (Main Plugin)                  │ │
│  │  • FlutterPlugin protocol                                         │ │
│  │  • FlutterStreamHandler protocol                                  │ │
│  │  • Method call routing                                            │ │
│  │  • Event sink management                                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                  WAEventEmitter (Thread-Safe)                     │ │
│  │  • Serial queue for event sink access                             │ │
│  │  • Auto-dispatch to main thread                                   │ │
│  │  • Event validation                                               │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                    ↑                                    │
│                    ┌───────────────┴───────────────┐                    │
│                    │                               │                    │
│  ┌─────────────────┴────────┐  ┌─────────────────┴─────────────┐       │
│  │   WAErrorHandler         │  │   WADeviceModel               │       │
│  │  • Error code mapping    │  │  • Device data structure      │       │
│  │  • NSError → Flutter     │  │  • Conversion utilities       │       │
│  │  • User-friendly msg     │  │  • JSON serialization         │       │
│  └──────────────────────────┘  └───────────────────────────────┘       │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                      MANAGER CLASSES                              │ │
│  ├───┬───────────────┬──────────────────┬─────────────────┬─────────┤ │
│  │   │               │                  │                 │         │ │
│  │   ↓               ↓                  ↓                 ↓         │ │
│  │ ┌─────────┐  ┌──────────┐  ┌──────────────┐  ┌───────────────┐  │ │
│  │ │  Scan   │  │   Pair   │  │     WiFi     │  │   Bluetooth   │  │ │
│  │ │ Manager │  │ Manager  │  │Config Manager│  │State Manager  │  │ │
│  │ └─────────┘  └──────────┘  └──────────────┘  └───────────────┘  │ │
│  │      │             │               │                  │          │ │
│  └──────┼─────────────┼───────────────┼──────────────────┼──────────┘ │
│         │             │               │                  │            │
└─────────┼─────────────┼───────────────┼──────────────────┼────────────┘
          │             │               │                  │
          ↓             ↓               ↓                  ↓
┌─────────────────────────────────────────────────────────────────────────┐
│                       NATIVE iOS LAYER                                  │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │                     CoreBluetooth Framework                       │ │
│  │  • CBCentralManager (Bluetooth state)                             │ │
│  │  • Scan for peripherals                                           │ │
│  │  • Device discovery                                               │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                                                         │
│  ┌───────────────────────────────────────────────────────────────────┐ │
│  │              SMART LOCK SDK (HXJBLESDK - To be integrated)        │ │
│  │  • HXScanAllDevicesHelper (Scanning)                              │ │
│  │  • HXAddBluetoothLockHelper (Pairing)                             │ │
│  │  • HXWiFiConfigHelper (WiFi Configuration)                        │ │
│  │  • HXServerManager (Server Registration)                          │ │
│  └───────────────────────────────────────────────────────────────────┘ │
│                                    │                                    │
└────────────────────────────────────┼────────────────────────────────────┘
                                     │
                                     ↓
                      ┌──────────────────────────────┐
                      │   SMART LOCK HARDWARE (BLE)  │
                      │  • BLE Advertisement         │
                      │  • Pairing Protocol          │
                      │  • WiFi Provisioning         │
                      └──────────────────────────────┘
```

---

## Data Flow Examples

### 1. Start Scan Flow
```
Flutter UI
    │
    ├─ methodChannel.invokeMethod('startScan', {...})
    │
    ↓
WiseApartmentPlugin
    │
    ├─ handleStartScan(args, result)
    ├─ Validate parameters
    ├─ Check Bluetooth state
    │
    ↓
WAScanManager
    │
    ├─ startScanWithTimeout(...)
    ├─ Call CoreBluetooth / SDK
    │
    ↓
CBCentralManager / HXScanAllDevicesHelper
    │
    ├─ Start BLE scanning
    ├─ Discover peripherals
    │
    ↓ (Callback for each device)
WAScanManager (Delegate)
    │
    ├─ Convert device to Flutter format
    │
    ↓
WAEventEmitter
    │
    ├─ emitEvent({type: "scanResult", device: {...}})
    ├─ Dispatch to main thread
    │
    ↓
Flutter EventChannel Listener
    │
    └─ Update UI with device
```

---

### 2. Pair Device Flow
```
Flutter UI
    │
    ├─ methodChannel.invokeMethod('pairDevice', {deviceId, token, name})
    │
    ↓
WiseApartmentPlugin
    │
    ├─ handlePairDevice(args, result)
    ├─ Validate deviceId required
    │
    ↓
WAPairManager
    │
    ├─ pairDeviceWithId(...)
    ├─ Set isPairingInProgress = YES
    │
    ↓
HXAddBluetoothLockHelper
    │
    ├─ addDeviceWithMac(...)
    ├─ Delegate progress callbacks
    │
    ↓ (Multiple progress updates)
WAPairManager (Delegate)
    │
    ├─ pairingProgress: 25%  →  WAEventEmitter → Flutter
    ├─ pairingProgress: 50%  →  WAEventEmitter → Flutter
    ├─ pairingProgress: 75%  →  WAEventEmitter → Flutter
    │
    ↓ (On success)
    ├─ Extract device info & DNA
    ├─ pairingSuccess event  →  WAEventEmitter → Flutter
    ├─ Call completion block  →  FlutterResult(success)
    │
    └─ Flutter UI shows success dialog
```

---

### 3. Configure WiFi Flow
```
Flutter UI
    │
    ├─ methodChannel.invokeMethod('configureWifi', {deviceId, ssid, password, ...})
    │
    ↓
WiseApartmentPlugin
    │
    ├─ handleConfigureWifi(args, result)
    ├─ Validate ssid, password required
    │
    ↓
WAWiFiConfigManager
    │
    ├─ configureWifiForDevice(...)
    ├─ Setup timeout timer
    │
    ↓
HXWiFiConfigHelper
    │
    ├─ configureDevice(...)
    ├─ Send credentials over BLE
    │
    ↓ (Progress updates)
    ├─ wifiProgress: "sending" 30%     →  WAEventEmitter → Flutter
    ├─ wifiProgress: "connecting" 60%  →  WAEventEmitter → Flutter
    ├─ wifiProgress: "verifying" 90%   →  WAEventEmitter → Flutter
    │
    ↓ (On success)
    ├─ wifiSuccess event  →  WAEventEmitter → Flutter
    └─ Call completion    →  FlutterResult(success)
```

---

## Threading Model

```
┌─────────────────────────────────────────────────────────────┐
│                    Thread Diagram                           │
├─────────────────────────────────────────────────────────────┤
│                                                             │
│  ┌──────────────────────────────────────────────────────┐  │
│  │              MAIN THREAD (UI Thread)                 │  │
│  │                                                       │  │
│  │  • Flutter method calls                              │  │
│  │  • FlutterResult callbacks                           │  │
│  │  • FlutterEventSink emissions   ◄────────┐           │  │
│  │  • UI updates                            │           │  │
│  └──────────────────────────────────────────┼───────────┘  │
│                       │                     │              │
│                       │ dispatch_async      │              │
│                       │ to background       │              │
│                       ↓                     │              │
│  ┌─────────────────────────────────────────┼───────────┐  │
│  │         BACKGROUND QUEUE                │           │  │
│  │                                          │           │  │
│  │  • SDK operations (scan, pair, config)  │           │  │
│  │  • Heavy processing                     │           │  │
│  │  • Network calls                        │           │  │
│  │  • Timeouts                             │           │  │
│  └─────────────────────────────────────────┼───────────┘  │
│                                             │              │
│                                             │              │
│  ┌─────────────────────────────────────────┼───────────┐  │
│  │    EVENT EMITTER SERIAL QUEUE           │           │  │
│  │                                          │           │  │
│  │  • Thread-safe event sink access        │           │  │
│  │  • Event queuing                        │           │  │
│  │  • Dispatch to main for emission  ──────┘           │  │
│  └──────────────────────────────────────────────────────┘  │
│                                                             │
└─────────────────────────────────────────────────────────────┘
```

---

## Memory Management

```
┌────────────────────────────────────────────────────────────┐
│               Object Ownership Graph                       │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  WiseApartmentPlugin (strong)                              │
│         │                                                  │
│         ├── strong → WAEventEmitter                        │
│         ├── strong → WAScanManager                         │
│         ├── strong → WAPairManager                         │
│         ├── strong → WAWiFiConfigManager                   │
│         └── strong → WABluetoothStateManager               │
│                                                            │
│  WAScanManager                                             │
│         ├── weak → WAEventEmitter  (avoid retain cycle)   │
│         └── strong → CBCentralManager                      │
│                                                            │
│  WAPairManager                                             │
│         ├── weak → WAEventEmitter  (avoid retain cycle)   │
│         └── strong → SDK Helper                            │
│                                                            │
│  WAEventEmitter                                            │
│         └── copy → FlutterEventSink (cleared on cancel)   │
│                                                            │
│  Cleanup on detachFromEngine:                              │
│         • Stop all operations                              │
│         • Clear event sink                                 │
│         • Invalidate timers                                │
│         • Release managers                                 │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## Error Propagation

```
┌────────────────────────────────────────────────────────────┐
│                  Error Flow Diagram                        │
├────────────────────────────────────────────────────────────┤
│                                                            │
│  SDK Error (NSError)                                       │
│         │                                                  │
│         ↓                                                  │
│  Manager catches error                                     │
│         │                                                  │
│         ├─ Convert to WAErrorCode (mapping)               │
│         │                                                  │
│         ├─ Option 1: FlutterResult(error)                 │
│         │      └─ WAErrorHandler.flutterErrorFromNSError  │
│         │              │                                   │
│         │              └─ FlutterError(code, msg, details) │
│         │                       │                          │
│         │                       ↓                          │
│         │                  Flutter (PlatformException)     │
│         │                                                  │
│         └─ Option 2: Event emission                       │
│                └─ {type: "xxxError", code, message}       │
│                        │                                   │
│                        ↓                                   │
│                   Flutter EventChannel                     │
│                                                            │
│  Flutter App handles error:                               │
│    • Show dialog                                          │
│    • Retry logic                                          │
│    • Update UI state                                      │
│    • Log to analytics                                     │
│                                                            │
└────────────────────────────────────────────────────────────┘
```

---

## File Dependencies

```
WiseApartmentPlugin.m
    ├── imports → WAEventEmitter.h
    ├── imports → WAScanManager.h
    ├── imports → WAPairManager.h
    ├── imports → WAWiFiConfigManager.h
    ├── imports → WABluetoothStateManager.h
    └── imports → WAErrorHandler.h

WAScanManager.m
    ├── imports → WAEventEmitter.h
    ├── imports → WAErrorHandler.h
    ├── imports → WADeviceModel.h (future)
    └── imports → CoreBluetooth.framework
    └── TODO: imports → HXJBLESDK (HXScanAllDevicesHelper)

WAPairManager.m
    ├── imports → WAEventEmitter.h
    ├── imports → WAErrorHandler.h
    └── TODO: imports → HXJBLESDK (HXAddBluetoothLockHelper)

WAWiFiConfigManager.m
    ├── imports → WAEventEmitter.h
    ├── imports → WAErrorHandler.h
    └── TODO: imports → HXJBLESDK (HXWiFiConfigHelper)

WABluetoothStateManager.m
    ├── imports → WAEventEmitter.h
    └── imports → CoreBluetooth.framework

WAEventEmitter.m
    └── imports → Flutter.framework

WAErrorHandler.m
    └── imports → Flutter.framework

WADeviceModel.m
    └── imports → CoreBluetooth.framework
```

---

This architecture ensures:
✅ Clear separation of concerns  
✅ Thread safety at all levels  
✅ No circular dependencies  
✅ Easy SDK integration  
✅ Testable components  
✅ Memory-safe design
