# Detailed Response Flow with JSON Payloads

## Complete Journey: Android/iOS → Flutter → Backend API

---

# ANDROID Flow - Detailed with JSON

## 1️⃣ Flutter calls startAddLockKeyStream()

### Dart Code:
```dart
await platform.invokeMethod('addLockKeyStream', {
  'lockMac': 'AA:BB:CC:DD:EE:FF',
  'dnaAes128Key': 'A1B2C3D4E5F6A7B8C9D0E1F2A3B4C5D6',
  'authorizedRoot': 'root123',
  'action': {
    'addedKeyType': 1,        // 1=fingerprint, 4=card, 8=remote
    'authorMode': 0,          // 0=biometric, 1=password
    'password': '',
    'addedKeyGroupId': 900,
    'addedKeyId': 1,
    'vaildNumber': 255,
    'validStartTime': 0,
    'validEndTime': 4294967295,
    'vaildMode': 0,
    'week': 127,
    'dayStartTimes': 0,
    'dayEndTimes': 1439,
    'modifyTimestamp': 1683000000
  }
});
```

### JSON Sent to Android:
```json
{
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "dnaAes128Key": "A1B2C3D4E5F6A7B8C9D0E1F2A3B4C5D6",
  "authorizedRoot": "root123",
  "action": {
    "addedKeyType": 1,
    "authorMode": 0,
    "password": "",
    "addedKeyGroupId": 900,
    "addedKeyId": 1,
    "vaildNumber": 255,
    "validStartTime": 0,
    "validEndTime": 4294967295,
    "vaildMode": 0,
    "week": 127,
    "dayStartTimes": 0,
    "dayEndTimes": 1439,
    "modifyTimestamp": 1683000000
  }
}
```

---

## 2️⃣ WiseApartmentPlugin receives the call

**File:** `WiseApartmentPlugin.java:542-586`

```java
case "addLockKeyStream":
    if (lockManager != null) {
        if (eventSink != null) {
            // ✅ Start streaming with EventChannel listener active
            lockManager.addLockKeyStream((Map<String, Object>) call.arguments, callback);
            
            // Immediately return to Dart
            safeResult.success({"streaming": true});
        }
    }
    break;
```

### JSON Returned to Dart (Immediate):
```json
{
  "streaming": true
}
```

---

## 3️⃣ BleLockManager.addLockKeyStream() processes request

**File:** `BleLockManager.java:1055-1192`

```java
public void addLockKeyStream(Map<String, Object> args, AddLockKeyStreamCallback callback) {
    // Step 1: Create AddLockKeyAction from args
    AddLockKeyAction action = new AddLockKeyAction();
    action.setBaseAuthAction(PluginUtils.createAuthAction(args));
    action.setAddedKeyType(1);         // fingerprint
    action.setAuthorMode(0);           // biometric
    action.setAddedKeyID(1);
    action.setAddedKeyGroupId(900);
    action.setVaildNumber(255);
    action.setValidStartTime(0);
    action.setValidEndTime(4294967295);
    action.setVaildMode(1);            // converted: 0→1 (single validity window)
    action.setWeek(127);
    action.setDayStartTimes(0);
    action.setDayEndTimes(1439);
    action.setModifyTimestamp(1683000000);
    
    // Step 2: Call native SDK
    bleClient.addLockKey(action, new FunCallback<AddLockKeyResult>() {
        @Override
        public void onResponse(Response<AddLockKeyResult> response) {
            // Step 3: SDK returns response with enrollment progress
            // First enrollment attempt returns: authTotal=5, authCount=1
```

---

## 4️⃣ HXJ BLE SDK returns first progress response

The vendor SDK calls the callback with:
- `response.code()` = `0x01` (ACK_STATUS_SUCCESS)
- `response.body()` = AddLockKeyResult object
  - Has field: `authTotal = 5` (needs 5 fingerprints)
  - Has field: `authCount = 1` (1 enrolled so far)
- `response.getLockMac()` = "AA:BB:CC:DD:EE:FF"

---

## 5️⃣ BleLockManager builds and emits first CHUNK event

### JSON Built in BleLockManager (Progress - 1/5):

```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "modelType": "AddLockKeyResult",
    "authTotal": 5,
    "authCount": 1,
    "keyId": 0,
    "keyType": 1,
    "keyGroupId": 900,
    "validStartTime": 0,
    "validEndTime": 4294967295,
    "week": 127,
    "dayStartTimes": 0,
    "dayEndTimes": 1439,
    "vaildMode": 1,
    "vaildNumber": 255,
    "modifyTimestamp": 1683000000,
    "status": 0
  },
  "type": "addLockKeyChunk",
  "message": "Please enroll fingerprint (1/5)"
}
```

### Callback Invoked:
```java
callback.onChunk(event);  // ← Send to WiseApartmentPlugin
```

---

## 6️⃣ WiseApartmentPlugin routes to EventChannel

**File:** `WiseApartmentPlugin.java:547-553`

```java
@Override
public void onChunk(final Map<String, Object> chunkEvent) {
    new android.os.Handler(android.os.Looper.getMainLooper()).post(new Runnable() {
        @Override
        public void run() {
            if (eventSink != null) {
                eventSink.success(chunkEvent);  // ← Send JSON to Flutter
            }
        }
    });
}
```

---

## 7️⃣ Flutter receives CHUNK event via EventChannel

### EventChannel Listener in Dart:
```dart
EventChannel('wise_apartment/ble_events').receiveBroadcastStream().listen(
    (event) {
        // event is the JSON from Android
        print('Received: ${event['type']}');  // Prints: "addLockKeyChunk"
    }
);
```

### JSON Received by Flutter (Progress 1/5):
```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "modelType": "AddLockKeyResult",
    "authTotal": 5,
    "authCount": 1,
    "keyId": 0,
    "keyType": 1,
    "keyGroupId": 900,
    "validStartTime": 0,
    "validEndTime": 4294967295,
    "week": 127,
    "dayStartTimes": 0,
    "dayEndTimes": 1439,
    "vaildMode": 1,
    "vaildNumber": 255,
    "modifyTimestamp": 1683000000,
    "status": 0
  },
  "type": "addLockKeyChunk",
  "message": "Please enroll fingerprint (1/5)"
}
```

---

## 8️⃣ SDK Returns More Progress (2/5, 3/5, 4/5)

**Same flow repeats:**
- User enrolls more fingerprints
- SDK calls callback multiple times
- Each time returns same JSON structure but with incremented `authCount`

### 2nd Progress (2/5):
```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "authTotal": 5,
    "authCount": 2
  },
  "type": "addLockKeyChunk",
  "message": "Please enroll fingerprint (2/5)"
}
```

### 3rd Progress (3/5):
```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "authTotal": 5,
    "authCount": 3
  },
  "type": "addLockKeyChunk",
  "message": "Please enroll fingerprint (3/5)"
}
```

---

## 9️⃣ SDK Returns Completion (5/5)

When user completes all 5 fingerprints:

### JSON Built in BleLockManager (Complete):
```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "modelType": "AddLockKeyResult",
    "authTotal": 5,
    "authCount": 5,
    "keyId": 1,
    "keyType": 1,
    "keyGroupId": 900,
    "validStartTime": 0,
    "validEndTime": 4294967295,
    "week": 127,
    "dayStartTimes": 0,
    "dayEndTimes": 1439,
    "vaildMode": 1,
    "vaildNumber": 255,
    "modifyTimestamp": 1683000000,
    "status": 0,
    "addTime": 1683100000,
    "sequenceNumber": 12345
  },
  "type": "addLockKeyDone"
}
```

### Callback Invoked:
```java
callback.onDone(event);  // ← Send to WiseApartmentPlugin
```

### Flutter Receives:
```dart
// In EventChannel listener
if (event['type'] == 'addLockKeyDone') {
    // 🎉 Enrollment complete!
    // Now make API call to backend
}
```

---

## 🔟 Flutter Makes API Call to Backend

### Dart Code:
```dart
final response = await _dio.post(
    'https://your-api.com/api/lock-keys/add',
    data: {
        'lockMac': event['lockMac'],
        'keyData': event['body'],
        'authTotal': event['body']['authTotal'],
        'authCount': event['body']['authCount'],
        'timestamp': DateTime.now().toIso8601String(),
    }
);
```

### JSON Sent to Backend:
```json
{
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "keyData": {
    "modelType": "AddLockKeyResult",
    "authTotal": 5,
    "authCount": 5,
    "keyId": 1,
    "keyType": 1,
    "keyGroupId": 900,
    "validStartTime": 0,
    "validEndTime": 4294967295,
    "week": 127,
    "dayStartTimes": 0,
    "dayEndTimes": 1439,
    "vaildMode": 1,
    "vaildNumber": 255,
    "modifyTimestamp": 1683000000,
    "status": 0,
    "addTime": 1683100000,
    "sequenceNumber": 12345
  },
  "authTotal": 5,
  "authCount": 5,
  "timestamp": "2023-05-03T10:30:45.123Z"
}
```

### Backend Response (Expected):
```json
{
  "success": true,
  "message": "Key saved successfully",
  "data": {
    "id": "key_123456",
    "lockMac": "AA:BB:CC:DD:EE:FF",
    "keyType": "fingerprint",
    "enrollments": 5,
    "createdAt": "2023-05-03T10:30:45.123Z"
  }
}
```

---

## ❌ Error Scenario

If error occurs during enrollment (e.g., timeout, invalid lock):

### SDK Returns Error:
```java
response.code() = 0xE2  // Device busy
response.isSuccessful() = false
```

### JSON Built in BleLockManager (Error):
```json
{
  "code": 226,
  "message": "Device busy, try again later",
  "ackMessage": "Device busy, try again later",
  "isSuccessful": false,
  "isError": true,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": null,
  "type": "addLockKeyError",
  "message": "Device busy, try again later"
}
```

### Callback Invoked:
```java
callback.onError(event);  // ← Send to WiseApartmentPlugin
```

### Flutter Receives:
```dart
if (event['type'] == 'addLockKeyError') {
    print('❌ Error: ${event['message']}');
    // Show error dialog to user
    // Do NOT make API call
}
```

---

---

# iOS Flow - Detailed with JSON

## 1️⃣ Flutter calls startAddLockKeyStream()

### Same as Android - Dart Code:
```dart
await platform.invokeMethod('addLockKeyStream', {
  'lockMac': 'AA:BB:CC:DD:EE:FF',
  'dnaAes128Key': 'A1B2C3D4E5F6A7B8C9D0E1F2A3B4C5D6',
  'authorizedRoot': 'root123',
  'action': { ... }
});
```

---

## 2️⃣ WiseApartmentPlugin receives the call

**File:** `WiseApartmentPlugin.m:328-342`

```objc
else if ([@"addLockKeyStream" isEqualToString:method]) {
    NSDictionary *params = args;
    
    if ([self.eventEmitter hasActiveListener]) {
        // ✅ EventChannel listener is active
        [self.lockManager addLockKeyStream:params eventEmitter:self.eventEmitter];
        
        result(@{ 
            @"streaming": @YES, 
            @"message": @"addLockKeyStream started - listen to EventChannel" 
        });
    }
}
```

### JSON Returned to Dart (Immediate):
```json
{
  "streaming": true,
  "message": "addLockKeyStream started - listen to EventChannel"
}
```

---

## 3️⃣ BleLockManager.addLockKeyStream() processes request

**File:** `BleLockManager.m:847-980`

```objc
- (void)addLockKeyStream:(NSDictionary *)args eventEmitter:(WAEventEmitter *)eventEmitter {
    // Step 1: Create HXBLEAddOtherKeyParams from args
    HXBLEAddOtherKeyParams *addKeyParams = [[HXBLEAddOtherKeyParams alloc] init];
    addKeyParams.keyType = KSHKeyType_Fingerprint;  // 1 = fingerprint
    addKeyParams.lockMac = mac;
    addKeyParams.keyGroupId = 900;
    addKeyParams.vaildNumber = 255;
    addKeyParams.validStartTime = 0;
    addKeyParams.validEndTime = 0xFFFFFFFF;
    addKeyParams.authMode = 1;  // Single validity window
    addKeyParams.week = 127;
    addKeyParams.dayStartTimes = 0;
    addKeyParams.dayEndTimes = 1439;
    
    // Step 2: Call native SDK
    [HXBluetoothLockHelper addKey:addKeyParams 
        completionBlock:^(KSHStatusCode statusCode, NSString *reason, HXKeyModel *keyObj, int authTotal, int authCount) {
            // Step 3: SDK returns with enrollment progress
```

---

## 4️⃣ HXJ BLE SDK returns first progress response

The vendor SDK calls the completion block with:
- `statusCode` = `KSHStatusCode_Success` (0x01)
- `reason` = "Operation successful"
- `keyObj` = HXKeyModel instance (converted to dict)
- `authTotal` = 5 (needs 5 fingerprints)
- `authCount` = 1 (1 enrolled so far)

---

## 5️⃣ BleLockManager builds and emits first CHUNK event

### Objective-C Code:
```objc
NSMutableDictionary *body = [NSMutableDictionary dictionary];
if (keyObj != nil) {
    NSDictionary *keyMap = [keyObj dicFromObject];
    body[@"keyObj"] = keyMap;
}
body[@"authTotal"] = @(authTotal);      // 5
body[@"authCount"] = @(authCount);      // 1
body[@"statusCode"] = @((int)statusCode);
body[@"lockMac"] = mac;

NSMutableDictionary *event = [[self responseMapWithCode:(int)statusCode 
                                                message:reason 
                                                lockMac:mac 
                                                   body:body] mutableCopy];

event[@"type"] = @"addLockKeyChunk";
event[@"message"] = [NSString stringWithFormat:@"Please enroll fingerprint (%d/%d)", authCount, authTotal];

[eventEmitter emitEvent:event];  // ← Send to Flutter
```

### JSON Built in BleLockManager (Progress - 1/5):
```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "keyObj": {
      "keyID": 1,
      "keyType": 1,
      "keyGroupId": 900,
      "validStartTime": 0,
      "validEndTime": 4294967295,
      "week": 127,
      "dayStartTimes": 0,
      "dayEndTimes": 1439,
      "authMode": 1,
      "vaildNumber": 255,
      "modelType": "HXKeyModel"
    },
    "authTotal": 5,
    "authCount": 1,
    "statusCode": 1,
    "lockMac": "AA:BB:CC:DD:EE:FF"
  },
  "type": "addLockKeyChunk",
  "message": "Please enroll fingerprint (1/5)"
}
```

---

## 6️⃣ WAEventEmitter routes to EventChannel

**File:** `WAEventEmitter.m:88-110`

```objc
- (void)emitEvent:(NSDictionary *)event {
    if (!event) return;
    
    dispatch_queue_t q = [self ensureEventQueue];
    
    dispatch_async(q, ^{
        if (self.flutterSink) {
            self.flutterSink(event);  // ← Send JSON to Flutter
        }
    });
}
```

---

## 7️⃣ Flutter receives CHUNK event via EventChannel

### Same EventChannel as Android:
```dart
EventChannel('wise_apartment/ble_events').receiveBroadcastStream().listen(
    (event) {
        // Same JSON structure on both platforms!
        print('${event['type']}: ${event['message']}');
    }
);
```

### JSON Received by Flutter (Progress 1/5):
```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "keyObj": {
      "keyID": 1,
      "keyType": 1,
      "keyGroupId": 900,
      "validStartTime": 0,
      "validEndTime": 4294967295,
      "week": 127,
      "dayStartTimes": 0,
      "dayEndTimes": 1439,
      "authMode": 1,
      "vaildNumber": 255
    },
    "authTotal": 5,
    "authCount": 1,
    "statusCode": 1,
    "lockMac": "AA:BB:CC:DD:EE:FF"
  },
  "type": "addLockKeyChunk",
  "message": "Please enroll fingerprint (1/5)"
}
```

---

## 8️⃣ SDK Returns More Progress (2/5, 3/5, 4/5)

**Same flow repeats** with incremented `authCount`

---

## 9️⃣ SDK Returns Completion (5/5)

### JSON Built in BleLockManager (Complete):
```json
{
  "code": 1,
  "message": "Operation successful",
  "ackMessage": "Operation successful",
  "isSuccessful": true,
  "isError": false,
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "body": {
    "keyObj": {
      "keyID": 1,
      "keyType": 1,
      "keyGroupId": 900,
      "validStartTime": 0,
      "validEndTime": 4294967295,
      "week": 127,
      "dayStartTimes": 0,
      "dayEndTimes": 1439,
      "authMode": 1,
      "vaildNumber": 255,
      "addTime": 1683100000,
      "modelType": "HXKeyModel"
    },
    "authTotal": 5,
    "authCount": 5,
    "statusCode": 1,
    "lockMac": "AA:BB:CC:DD:EE:FF"
  },
  "type": "addLockKeyDone"
}
```

---

## 🔟 Flutter Makes API Call (Same as Android)

### JSON Sent to Backend:
```json
{
  "lockMac": "AA:BB:CC:DD:EE:FF",
  "keyData": {
    "keyObj": {
      "keyID": 1,
      "keyType": 1,
      "keyGroupId": 900,
      "validStartTime": 0,
      "validEndTime": 4294967295,
      "week": 127,
      "dayStartTimes": 0,
      "dayEndTimes": 1439,
      "authMode": 1,
      "vaildNumber": 255,
      "addTime": 1683100000
    },
    "authTotal": 5,
    "authCount": 5,
    "statusCode": 1,
    "lockMac": "AA:BB:CC:DD:EE:FF"
  },
  "authTotal": 5,
  "authCount": 5,
  "timestamp": "2023-05-03T10:30:45.123Z"
}
```

---

---

# Complete Flutter Implementation with JSON Handling

## lib/services/lock_key_service.dart

```dart
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

class LockKeyService {
  static const platform = MethodChannel('wise_apartment/methods');
  static const eventChannel = EventChannel('wise_apartment/ble_events');
  
  final Dio _dio = Dio();
  StreamSubscription? _eventSubscription;

  Future<void> startAddLockKeyStream({
    required String lockMac,
    required String dnaAes128Key,
    required String authorizedRoot,
    required int addedKeyType,
    required int authorMode,
    required Function(Map<String, dynamic>) onProgress,
    required Function(Map<String, dynamic>) onComplete,
    required Function(String) onError,
  }) async {
    try {
      print('📱 Calling addLockKeyStream...');
      
      // Call platform method
      final result = await platform.invokeMethod('addLockKeyStream', {
        'lockMac': lockMac,
        'dnaAes128Key': dnaAes128Key,
        'authorizedRoot': authorizedRoot,
        'action': {
          'addedKeyType': addedKeyType,
          'authorMode': authorMode,
          'password': '',
          'addedKeyGroupId': 900,
          'addedKeyId': 1,
          'vaildNumber': 255,
          'validStartTime': 0,
          'validEndTime': 0xFFFFFFFF,
          'vaildMode': 0,
          'week': 127,
          'dayStartTimes': 0,
          'dayEndTimes': 1439,
          'modifyTimestamp': DateTime.now().millisecondsSinceEpoch ~/ 1000,
        }
      });

      print('✅ Streaming started: $result');
      print('📝 JSON returned: ${jsonEncode(result)}');

      // Listen to EventChannel
      _eventSubscription = eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          // Event is received as Map<String, dynamic>
          final eventMap = Map<String, dynamic>.from(event);
          
          print('\n🔔 EventChannel event received:');
          print('📝 JSON: ${jsonEncode(eventMap)}');
          
          final type = eventMap['type'] as String?;
          final code = eventMap['code'] as int?;
          final message = eventMap['message'] as String?;
          final isSuccessful = eventMap['isSuccessful'] as bool?;
          final isError = eventMap['isError'] as bool?;
          final lockMacReturned = eventMap['lockMac'] as String?;
          final body = eventMap['body'] as Map<String, dynamic>?;

          print('├─ type: $type');
          print('├─ code: $code');
          print('├─ message: $message');
          print('├─ isSuccessful: $isSuccessful');
          print('├─ isError: $isError');
          print('├─ lockMac: $lockMacReturned');
          print('├─ body: ${jsonEncode(body)}');

          switch (type) {
            case 'addLockKeyChunk':
              // Progress update
              print('⏳ Enrollment progress...');
              final authCount = body?['authCount'] ?? 0;
              final authTotal = body?['authTotal'] ?? 0;
              print('   Progress: $authCount/$authTotal fingerprints');
              onProgress(eventMap);
              break;

            case 'addLockKeyDone':
              // Enrollment complete
              print('✅ Enrollment COMPLETE!');
              print('   keyId: ${body?['keyId']}');
              print('   keyType: ${body?['keyType']}');
              
              // Make API call
              _makeApiCall(lockMacReturned ?? lockMac, body ?? {})
                  .then((_) => onComplete(eventMap))
                  .catchError((e) => onError(e.toString()));
              break;

            case 'addLockKeyError':
              // Error occurred
              final errorMsg = message ?? 'Unknown error';
              print('❌ ERROR: $errorMsg');
              print('   code: $code');
              print('   ackMessage: ${eventMap['ackMessage']}');
              onError(errorMsg);
              break;

            default:
              print('⚠️ Unknown event type: $type');
          }
        },
        onError: (error) {
          print('❌ Stream error: $error');
          onError(error.toString());
        },
      );
    } catch (e) {
      print('❌ Exception: $e');
      onError(e.toString());
    }
  }

  Future<void> _makeApiCall(String lockMac, Map<String, dynamic> body) async {
    try {
      print('\n📤 Making API call to backend...');
      
      // Build request payload
      final requestPayload = {
        'lockMac': lockMac,
        'keyData': body,
        'authTotal': body['authTotal'] ?? 0,
        'authCount': body['authCount'] ?? 0,
        'timestamp': DateTime.now().toIso8601String(),
      };
      
      print('📝 Request JSON:');
      print(jsonEncode(requestPayload));

      // Make POST request
      final response = await _dio.post(
        'https://your-api.com/api/lock-keys/add',
        data: requestPayload,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer YOUR_TOKEN',
          },
        ),
      );

      // Handle response
      print('\n✅ Backend response (${response.statusCode}):');
      print('📝 Response JSON:');
      print(jsonEncode(response.data));

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('\n✅ Key saved successfully to backend!');
      } else {
        throw Exception('Server returned ${response.statusCode}');
      }
    } on DioException catch (e) {
      print('\n❌ API error: ${e.message}');
      if (e.response != null) {
        print('📝 Error response: ${jsonEncode(e.response?.data)}');
      }
      rethrow;
    } catch (e) {
      print('\n❌ Unexpected error: $e');
      rethrow;
    }
  }

  void dispose() {
    _eventSubscription?.cancel();
  }
}
```

---

# JSON Response Summary Table

## All Possible Response Types

| Event Type | code | isSuccessful | body.authTotal | body.authCount | When | Action |
|------------|------|--------------|-----------------|-----------------|------|--------|
| addLockKeyChunk | 1 | true | 5 | 1,2,3,4 | Enrollment in progress (1-4/5) | Show progress bar |
| addLockKeyChunk | 1 | true | 5 | 2 | Enrollment in progress (2/5) | Show progress bar |
| addLockKeyChunk | 1 | true | 5 | 3 | Enrollment in progress (3/5) | Show progress bar |
| addLockKeyChunk | 1 | true | 5 | 4 | Enrollment in progress (4/5) | Show progress bar |
| addLockKeyDone | 1 | true | 5 | 5 | Enrollment complete (5/5) | Make API call |
| addLockKeyDone | 1 | true | 0 | 0 | Single-step key (password, card) | Make API call |
| addLockKeyError | 0x02 | false | - | - | Password error | Show error message |
| addLockKeyError | 0xE2 | false | - | - | Device busy | Show error message |
| addLockKeyError | 0xFF05 | false | - | - | Bluetooth disconnected | Show error message |

---

# Complete Request/Response Flow Diagram

```
┌─────────────────────────────────────────────────────────────────────────┐
│ FLUTTER APP                                                             │
│ Call: platform.invokeMethod('addLockKeyStream', {...})                 │
│       ↓                                                                  │
│       Immediate JSON response: {"streaming": true}                      │
└─────────────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ NATIVE PLUGIN (Android/iOS)                                             │
│                                                                         │
│ ┌───────────────────────────────────────────────────────────────────┐ │
│ │ WiseApartmentPlugin                                               │ │
│ │ - Receives method call                                            │ │
│ │ - Passes to BleLockManager.addLockKeyStream()                     │ │
│ └───────────────────────────────────────────────────────────────────┘ │
│         ↓                                                              │
│ ┌───────────────────────────────────────────────────────────────────┐ │
│ │ BleLockManager.addLockKeyStream()                                 │ │
│ │ - Calls HXJ BLE SDK with AddLockKeyAction                         │ │
│ │ - Receives Response<AddLockKeyResult> from SDK                    │ │
│ │ - Builds JSON event with all response fields                      │ │
│ │ - Emits event via callback                                        │ │
│ └───────────────────────────────────────────────────────────────────┘ │
│         ↓                                                              │
│ ┌───────────────────────────────────────────────────────────────────┐ │
│ │ SDK Callbacks (multiple):                                         │ │
│ │ 1. callback.onChunk() - Progress 1/5                             │ │
│ │ 2. callback.onChunk() - Progress 2/5                             │ │
│ │ 3. callback.onChunk() - Progress 3/5                             │ │
│ │ 4. callback.onChunk() - Progress 4/5                             │ │
│ │ 5. callback.onDone()  - Complete 5/5                             │ │
│ │ OR callback.onError() - Error occurred                            │ │
│ └───────────────────────────────────────────────────────────────────┘ │
│         ↓                                                              │
│ ┌───────────────────────────────────────────────────────────────────┐ │
│ │ EventChannel Handler (WiseApartmentPlugin)                        │ │
│ │ - Routes callback events to eventSink                             │ │
│ │ - eventSink.success(jsonEvent) or eventSink.error(...)            │ │
│ └───────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ FLUTTER CODE                                                            │
│ EventChannel.receiveBroadcastStream().listen((event) { ... })          │
│                                                                         │
│ Receives multiple events:                                              │
│ 1. {"type": "addLockKeyChunk", "message": "Please enroll... (1/5)"}   │
│ 2. {"type": "addLockKeyChunk", "message": "Please enroll... (2/5)"}   │
│ 3. {"type": "addLockKeyChunk", "message": "Please enroll... (3/5)"}   │
│ 4. {"type": "addLockKeyChunk", "message": "Please enroll... (4/5)"}   │
│ 5. {"type": "addLockKeyDone", ...}                                    │
│    ↓                                                                    │
│    Makes API call with event['body']                                   │
│    ↓                                                                    │
│    POST https://your-api.com/api/lock-keys/add                        │
└─────────────────────────────────────────────────────────────────────────┘
         ↓
┌─────────────────────────────────────────────────────────────────────────┐
│ BACKEND API SERVER                                                      │
│ Receives: {"lockMac": "...", "keyData": {...}, ...}                    │
│ Returns: {"success": true, "id": "key_123456", ...}                    │
└─────────────────────────────────────────────────────────────────────────┘
```

---

# Key Takeaways

✅ **Same Flow on Android & iOS**
- Both return same JSON structure
- Same EventChannel for events
- Same progress tracking (authCount/authTotal)

✅ **Multiple Events**
- Progress events: `addLockKeyChunk` (1-4 times)
- Completion event: `addLockKeyDone` (once)
- Error event: `addLockKeyError` (if error)

✅ **Key Data Included**
- Full enrollment data in `body` field
- Can be directly sent to backend
- Contains keyId, keyType, validity times, etc.

✅ **No Chinese Errors**
- All error messages converted to English
- `message` and `ackMessage` fields provide description
- Suitable for displaying to users
