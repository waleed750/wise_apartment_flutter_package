# Complete Response Flow: Android vs iOS

## Overview

Both Android and iOS follow the **same pattern** for streaming responses:
1. Native code emits events via callback
2. Plugin routes events to Flutter via **EventChannel**
3. Flutter listens and handles events
4. API call made on completion

---

## ANDROID Flow (Java)

### Step 1️⃣: BleLockManager.java - Emit Events
**File:** `android/src/main/java/com/example/wise_apartment/utils/BleLockManager.java` (lines 1055-1192)

```java
public void addLockKeyStream(Map<String, Object> args, final AddLockKeyStreamCallback callback) {
    // Setup action with user parameters (password, fingerprint type, validity, etc.)
    AddLockKeyAction action = new AddLockKeyAction();
    action.setBaseAuthAction(PluginUtils.createAuthAction(args));
    // ... populate action fields ...
    
    // Call native SDK with callback
    bleClient.addLockKey(action, new FunCallback<AddLockKeyResult>() {
        @Override
        public void onResponse(Response<AddLockKeyResult> response) {
            try {
                // Build response event with all fields
                Map<String, Object> event = new HashMap<>();
                event.put("code", response.code());
                event.put("message", WiseStatusCode.description(response.code()));
                event.put("ackMessage", WiseStatusCode.description(response.code()));
                event.put("isSuccessful", response.isSuccessful());
                event.put("isError", !response.isSuccessful());
                event.put("lockMac", response.getLockMac() != null ? response.getLockMac() : "");
                
                // Extract key data via reflection mapping
                Map<String, Object> bodyMap = null;
                if (response.body() != null) {
                    bodyMap = objectToMap(response.body());
                    event.put("body", bodyMap);
                }
                
                // Check response status
                if (!response.isSuccessful()) {
                    // ❌ ERROR - emit error event
                    event.put("type", "addLockKeyError");
                    if (callback != null) callback.onError(event);
                    return;
                }
                
                // Extract authTotal and authCount from response body
                int authTotal = 0;
                int authCount = 0;
                if (bodyMap != null) {
                    if (bodyMap.containsKey("authTotal")) {
                        authTotal = parseInt(bodyMap.get("authTotal"), 0);
                    }
                    if (bodyMap.containsKey("authCount")) {
                        authCount = parseInt(bodyMap.get("authCount"), 0);
                    }
                }
                
                Log.d(TAG, "addLockKey - authTotal: " + authTotal + ", authCount: " + authCount);
                
                if (authTotal > 0 && authTotal == authCount) {
                    // ✅ COMPLETE - All fingerprints enrolled
                    Log.d(TAG, "Enrollment complete (" + authCount + "/" + authTotal + ")");
                    event.put("type", "addLockKeyDone");
                    if (callback != null) callback.onDone(event);
                } else if (authTotal > 0) {
                    // ⏳ PROGRESS - More fingerprints needed
                    String progressMsg = "Please enroll fingerprint (" + authCount + "/" + authTotal + ")";
                    Log.d(TAG, "Enrollment in progress - " + progressMsg);
                    event.put("type", "addLockKeyChunk");
                    event.put("message", progressMsg);
                    if (callback != null) callback.onChunk(event);
                } else {
                    // ✅ COMPLETE - Single-step key (password, card, etc.)
                    Log.d(TAG, "Single-step key added");
                    event.put("type", "addLockKeyDone");
                    if (callback != null) callback.onDone(event);
                }
            } catch (Throwable t) {
                // Exception handler
                if (callback != null) {
                    Map<String, Object> err = new HashMap<>();
                    err.put("type", "addLockKeyError");
                    err.put("message", t.getMessage());
                    callback.onError(err);
                }
            }
        }
        
        @Override
        public void onFailure(Throwable t) {
            // Network/BLE failure
            if (callback != null) {
                Map<String, Object> err = new HashMap<>();
                err.put("type", "addLockKeyError");
                err.put("message", t.getMessage());
                callback.onError(err);
            }
        }
    });
}
```

### Step 2️⃣: WiseApartmentPlugin.java - Route to EventChannel
**File:** `android/src/main/java/com/example/wise_apartment/WiseApartmentPlugin.java` (lines 542-586)

```java
case "addLockKeyStream":
    if (lockManager != null) {
        if (eventSink != null) {
            // Start streaming with callback that routes to EventChannel
            lockManager.addLockKeyStream((Map<String, Object>) call.arguments, 
                new com.example.wise_apartment.utils.BleLockManager.AddLockKeyStreamCallback() {
                    @Override
                    public void onChunk(final Map<String, Object> chunkEvent) {
                        // Route progress event to Flutter
                        new android.os.Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                if (eventSink != null) {
                                    eventSink.success(chunkEvent);  // ← Sends to Flutter EventChannel
                                }
                            }
                        });
                    }

                    @Override
                    public void onDone(final Map<String, Object> doneEvent) {
                        // Route completion event to Flutter
                        new android.os.Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                if (eventSink != null) {
                                    eventSink.success(doneEvent);  // ← Sends to Flutter EventChannel
                                }
                            }
                        });
                    }

                    @Override
                    public void onError(final Map<String, Object> errorEvent) {
                        // Route error event to Flutter
                        new android.os.Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
                            @Override
                            public void run() {
                                if (eventSink != null) {
                                    eventSink.error(
                                        String.valueOf(errorEvent.get("code")),
                                        String.valueOf(errorEvent.get("message")),
                                        errorEvent
                                    );  // ← Sends error to Flutter EventChannel
                                }
                            }
                        });
                    }
                });
            safeResult.success(java.util.Collections.singletonMap("streaming", true));
        } else {
            // No EventChannel listener - fallback to non-streaming
            lockManager.addLockKey((Map<String, Object>) call.arguments, safeResult);
        }
    }
    break;
```

### Step 3️⃣: EventChannel Registration
**File:** `android/src/main/java/com/example/wise_apartment/WiseApartmentPlugin.java` (lines 64-78)

```java
// Register EventChannel for streaming events
eventChannel = new EventChannel(flutterPluginBinding.getBinaryMessenger(), "wise_apartment/ble_events");
eventChannel.setStreamHandler(new EventChannel.StreamHandler() {
    @Override
    public void onListen(Object arguments, EventChannel.EventSink events) {
        eventSink = events;  // ← Store sink to send events
        Log.d(TAG, "EventChannel listener attached");
    }

    @Override
    public void onCancel(Object arguments) {
        eventSink = null;  // ← Clear sink when Flutter stops listening
        Log.d(TAG, "EventChannel listener cancelled");
    }
});
```

### 📤 Android Event Flow Diagram:
```
┌─────────────────────────────────────────────────────────────┐
│ HXJ BLE SDK (Vendor Library)                                │
│ - Handles fingerprint enrollment                             │
│ - Returns multiple responses with authTotal/authCount        │
└────────────────┬────────────────────────────────────────────┘
                 │ onResponse(Response<AddLockKeyResult>)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ BleLockManager.addLockKeyStream()                            │
│ - Extract authTotal & authCount from response.body()        │
│ - Build event map with all fields                            │
│ - Emit via callback.onChunk/onDone/onError()                │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ├─ onChunk() → Progress update
                 ├─ onDone()  → Enrollment complete
                 └─ onError() → Error occurred
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ WiseApartmentPlugin.addLockKeyStream handler                 │
│ - Routes callback events to eventSink                        │
│ - Runs on Main Looper thread                                 │
│ - Calls eventSink.success(event) or eventSink.error()       │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ EventChannel "wise_apartment/ble_events"                     │
│ - Platform side to Flutter side bridge                       │
│ - Sends events to listening Flutter code                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Flutter Code (EventChannel.receiveBroadcastStream())        │
│ - Receives events                                            │
│ - Handles addLockKeyChunk, addLockKeyDone, addLockKeyError  │
│ - Makes API call on completion                              │
└─────────────────────────────────────────────────────────────┘
```

---

## iOS Flow (Objective-C)

### Step 1️⃣: BleLockManager.m - Emit Events
**File:** `ios/Classes/Managers/BleLockManager.m` (lines 847-980)

```objc
- (void)addLockKeyStream:(NSDictionary *)args eventEmitter:(WAEventEmitter *)eventEmitter {
    NSLog(@"[BleLockManager] addLockKeyStream called");
    
    if (!eventEmitter) {
        NSLog(@"[BleLockManager] ✗ eventEmitter is nil");
        return;
    }

    // Initialize addHelper (HXJ SDK helper)
    if (!self.addHelper) {
        self.addHelper = [[HXAddBluetoothLockHelper alloc] init];
    }

    // Configure lock from args (MAC, DNA key, auth code)
    FlutterError *cfgErr = nil;
    if (![self configureLockFromArgs:args error:&cfgErr]) {
        [eventEmitter emitEvent:@{ 
            @"type": @"addLockKeyError", 
            @"message": cfgErr.message ?: @"Configuration error", 
            @"code": @(-1) 
        }];
        return;
    }

    NSString *mac = [PluginUtils lockMacFromArgs:args];
    NSDictionary *actionMap = [args[@"action"] isKindOfClass:[NSDictionary class]] ? args[@"action"] : @{};
    
    // Create key params (password, fingerprint, card, or remote control)
    HXBLEAddKeyBaseParams *addKeyParams = nil;
    int addedKeyType = [actionMap[@"addedKeyType"] intValue];
    
    if (addedKeyType == 1) {
        // 1 = Fingerprint
        HXBLEAddOtherKeyParams *otherParams = [[HXBLEAddOtherKeyParams alloc] init];
        otherParams.keyType = KSHKeyType_Fingerprint;
        addKeyParams = otherParams;
    } else if (addedKeyType == 4) {
        // 4 = Card
        HXBLEAddOtherKeyParams *otherParams = [[HXBLEAddOtherKeyParams alloc] init];
        otherParams.keyType = KSHKeyType_Card;
        addKeyParams = otherParams;
    } else if (addedKeyType == 8) {
        // 8 = Remote Control
        HXBLEAddOtherKeyParams *otherParams = [[HXBLEAddOtherKeyParams alloc] init];
        otherParams.keyType = KSHKeyType_RemoteControl;
        addKeyParams = otherParams;
    }
    
    // Populate parameters
    addKeyParams.lockMac = mac;
    addKeyParams.keyGroupId = [actionMap[@"addedKeyGroupId"] intValue] ?: 900;
    // ... populate other params ...
    
    // Call native SDK with completion block
    __weak typeof(self) weakSelf = self;
    @try {
        [HXBluetoothLockHelper addKey:addKeyParams 
            completionBlock:^(KSHStatusCode statusCode, NSString *reason, HXKeyModel *keyObj, int authTotal, int authCount) {
                __strong typeof(weakSelf) strongSelf = weakSelf;
                if (!strongSelf) return;
                @try {
                    NSLog(@"[BleLockManager] addKey callback - statusCode: %d, authTotal: %d, authCount: %d", 
                          (int)statusCode, authTotal, authCount);
                    
                    // Build response body with key object and auth info
                    NSMutableDictionary *body = [NSMutableDictionary dictionary];
                    if (keyObj != nil) {
                        NSDictionary *keyMap = [keyObj dicFromObject];
                        if ([keyMap isKindOfClass:[NSDictionary class]]) {
                            body[@"keyObj"] = keyMap;
                        }
                    }
                    body[@"authTotal"] = @(authTotal);
                    body[@"authCount"] = @(authCount);
                    body[@"statusCode"] = @((int)statusCode);
                    body[@"lockMac"] = mac;
                    
                    // Build standardized response map
                    NSMutableDictionary *event = [[strongSelf responseMapWithCode:(int)statusCode 
                                                                            message:reason 
                                                                            lockMac:mac 
                                                                               body:body] mutableCopy];
                    
                    // Handle errors
                    if (statusCode != KSHStatusCode_Success) {
                        NSLog(@"[BleLockManager] ✗ Error - emitting addLockKeyError");
                        event[@"type"] = @"addLockKeyError";
                        [eventEmitter emitEvent:event];  // ← Send error to Flutter
                        return;
                    }
                    
                    // Check enrollment status
                    if (authTotal == authCount) {
                        // ✅ COMPLETE - All fingerprints enrolled
                        NSLog(@"[BleLockManager] ✓ Enrollment complete (%d/%d)", authCount, authTotal);
                        event[@"type"] = @"addLockKeyDone";
                        [eventEmitter emitEvent:event];  // ← Send completion to Flutter
                    } else {
                        // ⏳ PROGRESS - More fingerprints needed
                        NSString *progressMsg;
                        if (authTotal == 255) {
                            progressMsg = [NSString stringWithFormat:@"Please enroll fingerprint (%d)", authCount];
                        } else {
                            progressMsg = [NSString stringWithFormat:@"Please enroll fingerprint (%d/%d)", authCount, authTotal];
                        }
                        NSLog(@"[BleLockManager] ⏳ Enrollment in progress - %@", progressMsg);
                        event[@"type"] = @"addLockKeyChunk";
                        event[@"message"] = progressMsg;
                        [eventEmitter emitEvent:event];  // ← Send progress to Flutter
                    }
                } @catch (NSException *exception) {
                    [eventEmitter emitEvent:@{ 
                        @"type": @"addLockKeyError", 
                        @"message": exception.reason ?: @"Exception in addKey callback", 
                        @"code": @(-1) 
                    }];
                }
            }];
    } @catch (NSException *exception) {
        [eventEmitter emitEvent:@{ 
            @"type": @"addLockKeyError", 
            @"message": exception.reason ?: @"Exception calling addKey", 
            @"code": @(-1) 
        }];
    }
}
```

### Step 2️⃣: WiseApartmentPlugin.m - Route to EventChannel
**File:** `ios/Classes/WiseApartmentPlugin.m` (lines 328-342)

```objc
else if ([@"addLockKeyStream" isEqualToString:method]) {
    NSLog(@"[WiseApartmentPlugin] handleAddLockKeyStream called");
    NSDictionary *params = [args isKindOfClass:[NSDictionary class]] ? args : @{};

    // Check if Flutter is listening to EventChannel
    if ([self.eventEmitter hasActiveListener]) {
        NSLog(@"[WiseApartmentPlugin] EventChannel listener active - starting addLockKeyStream");
        
        // Pass eventEmitter to manager - manager will emit events to it
        [self.lockManager addLockKeyStream:params eventEmitter:self.eventEmitter];
        
        // Return immediately - results come via EventChannel
        result(@{ 
            @"streaming": @YES, 
            @"message": @"addLockKeyStream started - listen to EventChannel" 
        });
    } else {
        NSLog(@"[WiseApartmentPlugin] No EventChannel listener - falling back to non-streaming");
        // Fallback to non-streaming version
        [self handleAddLockKey:args result:result];
    }
}
```

### Step 3️⃣: EventChannel Registration
**File:** `ios/Classes/WiseApartmentPlugin.m` (lines 79-83)

```objc
// Setup EventChannel for streaming events
instance.eventChannel = [FlutterEventChannel
                        eventChannelWithName:kEventChannelName  // "wise_apartment/ble_events"
                        binaryMessenger:[registrar messenger]];
[instance.eventChannel setStreamHandler:instance];
// Event emitter handles onListen/onCancel callbacks
```

### Step 4️⃣: WAEventEmitter.m - Manage Event Sink
**File:** `ios/Classes/Models/WAEventEmitter.m`

```objc
- (void)setEventSink:(FlutterEventSink)eventSink {
    NSLog(@"[WAEventEmitter] → setEventSink called (Flutter listening started)");
    dispatch_sync([self ensureEventQueue], ^{
        self.flutterSink = eventSink;  // ← Store sink
        NSLog(@"[WAEventEmitter] ✓ sink SET");
    });
}

- (void)clearEventSink {
    NSLog(@"[WAEventEmitter] → clearEventSink called (Flutter stopped listening)");
    dispatch_async([self ensureEventQueue], ^{
        self.flutterSink = nil;  // ← Clear sink
        NSLog(@"[WAEventEmitter] ✓ sink CLEARED");
    });
}

- (void)emitEvent:(NSDictionary *)event {
    if (!event) {
        NSLog(@"[WAEventEmitter] ✗ ERROR: Invalid event format");
        return;
    }

    dispatch_queue_t q = [self ensureEventQueue];
    
    // Ensure event emission happens on the event queue
    dispatch_async(q, ^{
        if (self.flutterSink) {
            NSLog(@"[WAEventEmitter] 📤 Emitting event: %@", event[@"type"]);
            self.flutterSink(event);  // ← Send to Flutter
        } else {
            NSLog(@"[WAEventEmitter] ✗ No sink available - event dropped");
        }
    });
}
```

### 📤 iOS Event Flow Diagram:
```
┌─────────────────────────────────────────────────────────────┐
│ HXJ BLE SDK (Framework)                                      │
│ - Handles fingerprint enrollment                             │
│ - Calls completion block with authTotal/authCount as params  │
└────────────────┬────────────────────────────────────────────┘
                 │ completionBlock(statusCode, reason, keyObj, authTotal, authCount)
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ BleLockManager.addLockKeyStream()                            │
│ - authTotal & authCount are direct parameters (not from body)│
│ - Build event map with all fields                            │
│ - Call eventEmitter.emitEvent()                              │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ├─ type: addLockKeyChunk (progress)
                 ├─ type: addLockKeyDone (complete)
                 └─ type: addLockKeyError (error)
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ WAEventEmitter.emitEvent()                                   │
│ - Dispatch to serial event queue                             │
│ - Call flutterSink(event)                                    │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ EventChannel "wise_apartment/ble_events"                     │
│ - Native side to Flutter side bridge                         │
│ - Sends events to listening Flutter code                     │
└────────────────┬────────────────────────────────────────────┘
                 │
                 ▼
┌─────────────────────────────────────────────────────────────┐
│ Flutter Code (EventChannel.receiveBroadcastStream())        │
│ - Receives events                                            │
│ - Handles addLockKeyChunk, addLockKeyDone, addLockKeyError  │
│ - Makes API call on completion                              │
└─────────────────────────────────────────────────────────────┘
```

---

## Side-by-Side Comparison

### Authentication Parameters

| Aspect | Android | iOS |
|--------|---------|-----|
| **Auth Source** | Response body via reflection | Direct callback parameters |
| **authTotal** | `bodyMap.get("authTotal")` | Direct parameter: `int authTotal` |
| **authCount** | `bodyMap.get("authCount")` | Direct parameter: `int authCount` |
| **Key Object** | `AddLockKeyResult` (mapped via reflection) | `HXKeyModel` (via `dicFromObject`) |

### Event Emission

| Aspect | Android | iOS |
|--------|---------|-----|
| **Callback Type** | `AddLockKeyStreamCallback` interface | `WAEventEmitter` injected |
| **Methods** | `onChunk()`, `onDone()`, `onError()` | `emitEvent()` (single method) |
| **Threading** | Main Looper handler | Serial dispatch queue |
| **Fallback** | Non-streaming `addLockKey()` | Non-streaming `handleAddLockKey()` |

### Response Structure

| Field | Android | iOS |
|-------|---------|-----|
| `code` | ✅ Yes | ✅ Yes |
| `message` | ✅ Yes | ✅ Yes |
| `ackMessage` | ✅ Yes | ✅ Yes |
| `isSuccessful` | ✅ Yes | ✅ Yes |
| `isError` | ✅ Yes | ✅ Yes |
| `lockMac` | ✅ Yes | ✅ Yes |
| `body` | ✅ Yes | ✅ Yes |
| `type` | ✅ Yes | ✅ Yes |
| `body.keyObj` | Via `objectToMap()` | Via `dicFromObject()` |
| `body.authTotal` | ✅ Yes (extracted) | ✅ Yes (direct param) |
| `body.authCount` | ✅ Yes (extracted) | ✅ Yes (direct param) |

---

## Key Differences

### 1️⃣ Parameter Passing
- **Android:** authTotal/authCount extracted from response body via reflection
- **iOS:** authTotal/authCount passed directly as callback parameters

### 2️⃣ Event Routing
- **Android:** Callback interface with `onChunk()`, `onDone()`, `onError()`
- **iOS:** Single `emitEvent()` method on WAEventEmitter

### 3️⃣ Threading
- **Android:** Uses `Handler(Looper.getMainLooper())` to post to main thread
- **iOS:** Uses `dispatch_queue_create()` for serial event queue

### 4️⃣ Fallback Behavior
- **Android:** Checks `eventSink != null` to determine streaming vs non-streaming
- **iOS:** Checks `[eventEmitter hasActiveListener]` to determine streaming vs non-streaming

### 5️⃣ Error Handling
- **Android:** Try-catch around callback invocation
- **iOS:** @try/@catch blocks around native SDK calls

---

## Flutter Code Works with Both!

The Flutter code you write **doesn't need to know the difference** between Android and iOS.

Both platforms send the same response structure to Flutter via the same EventChannel:

```dart
// This works on BOTH Android and iOS!
EventChannel('wise_apartment/ble_events').receiveBroadcastStream().listen(
    (event) {
        // event is the same structure on both platforms
        print('${event['type']}: ${event['message']}');
        
        if (event['type'] == 'addLockKeyChunk') {
            // Show progress
        } else if (event['type'] == 'addLockKeyDone') {
            // Make API call
        } else if (event['type'] == 'addLockKeyError') {
            // Show error
        }
    }
);
```

This is why **cross-platform development** with Flutter is powerful! 🎯
