# Response Flow: Native Code → Flutter → API Call

## 1. How Response Flows from Native to Flutter

### Flow Diagram:
```
Android Native Code (BleLockManager.java)
         ↓
    addLockKeyStream() emits events via callback
         ↓
    WiseApartmentPlugin.java (EventChannel handler)
         ↓
    eventSink.success(event) or eventSink.error()
         ↓
    Flutter EventChannel listens to "wise_apartment/ble_events"
         ↓
    Your Flutter Code receives events
         ↓
    API Call to Backend
```

### Step-by-Step:

#### **Step 1: Android Native Emits Events**
File: `BleLockManager.java` (lines 1055-1192)
```java
public void addLockKeyStream(Map<String, Object> args, final AddLockKeyStreamCallback callback) {
    // ... setup ...
    
    bleClient.addLockKey(action, new FunCallback<AddLockKeyResult>() {
        @Override
        public void onResponse(Response<AddLockKeyResult> response) {
            // Build event with response data
            Map<String, Object> event = new HashMap<>();
            event.put("code", response.code());
            event.put("message", WiseStatusCode.description(response.code()));
            event.put("ackMessage", WiseStatusCode.description(response.code()));
            event.put("isSuccessful", response.isSuccessful());
            event.put("isError", !response.isSuccessful());
            event.put("lockMac", response.getLockMac());
            event.put("body", objectToMap(response.body()));
            event.put("type", "addLockKeyChunk|addLockKeyDone|addLockKeyError");
            
            // Emit via callback
            if (statusCode == Success) {
                callback.onChunk(event);  // Progress
                // OR
                callback.onDone(event);   // Complete
            } else {
                callback.onError(event);  // Error
            }
        }
    });
}
```

#### **Step 2: Plugin Routes Events to Flutter**
File: `WiseApartmentPlugin.java` (lines 542-586)
```java
case "addLockKeyStream":
    if (eventSink != null) {
        lockManager.addLockKeyStream(args, new AddLockKeyStreamCallback() {
            @Override
            public void onChunk(final Map<String, Object> chunkEvent) {
                // Route chunk event to Flutter via EventChannel
                eventSink.success(chunkEvent);  // ← Flutter receives this
            }
            
            @Override
            public void onDone(final Map<String, Object> doneEvent) {
                // Route completion event to Flutter
                eventSink.success(doneEvent);   // ← Flutter receives this
            }
            
            @Override
            public void onError(final Map<String, Object> errorEvent) {
                // Route error to Flutter
                eventSink.error(code, message, details);  // ← Flutter receives this
            }
        });
        safeResult.success({"streaming": true});  // Initial confirmation
    }
    break;
```

#### **Step 3: Flutter Listens via EventChannel**
```dart
// In your Flutter controller/service
final EventChannel _bleEventChannel = EventChannel('wise_apartment/ble_events');

Future<void> listenToAddLockKeyStream() {
    _bleEventChannel.receiveBroadcastStream().listen(
        (event) {
            // This is the response from native code
            print('Received event: $event');
            // event contains: code, message, ackMessage, isSuccessful, isError, lockMac, body, type
            _handleAddLockKeyEvent(event);
        },
        onError: (error) {
            print('Stream error: $error');
        }
    );
}
```

---

## 2. Complete Flutter Implementation

### File: `lib/services/lock_key_service.dart`

```dart
import 'package:flutter/services.dart';
import 'package:dio/dio.dart';

class AddLockKeyResponse {
  final int code;
  final String message;
  final String ackMessage;
  final bool isSuccessful;
  final bool isError;
  final String lockMac;
  final Map<String, dynamic> body;
  final String type; // addLockKeyChunk, addLockKeyDone, addLockKeyError
  final String? progressMessage;

  AddLockKeyResponse.fromMap(Map<dynamic, dynamic> map)
      : code = map['code'] ?? -1,
        message = map['message'] ?? '',
        ackMessage = map['ackMessage'] ?? '',
        isSuccessful = map['isSuccessful'] ?? false,
        isError = map['isError'] ?? false,
        lockMac = map['lockMac'] ?? '',
        body = Map<String, dynamic>.from(map['body'] ?? {}),
        type = map['type'] ?? 'unknown',
        progressMessage = map['message'];
}

class LockKeyService {
  static const platform = MethodChannel('wise_apartment/methods');
  static const eventChannel = EventChannel('wise_apartment/ble_events');
  
  final Dio _dio = Dio();
  StreamSubscription? _eventSubscription;

  /// Initiate NFC/Fingerprint key enrollment with streaming
  Future<void> startAddLockKeyStream({
    required String lockMac,
    required String dnaAes128Key,
    required String authorizedRoot,
    required int addedKeyType, // 1=fingerprint, 4=card, 8=remote
    required int authorMode,   // 0=biometric/card, 1=password
    required Function(AddLockKeyResponse) onProgress,
    required Function(AddLockKeyResponse) onComplete,
    required Function(String) onError,
  }) async {
    try {
      // First, call the platform method to start streaming
      final result = await platform.invokeMethod('addLockKeyStream', {
        'lockMac': lockMac,
        'dnaAes128Key': dnaAes128Key,
        'authorizedRoot': authorizedRoot,
        'action': {
          'addedKeyType': addedKeyType,
          'authorMode': authorMode,
          'password': '', // Empty for biometric
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
      
      print('Streaming started: $result');
      
      // Listen to events from the stream
      _eventSubscription = eventChannel.receiveBroadcastStream().listen(
        (dynamic event) {
          final response = AddLockKeyResponse.fromMap(event);
          print('📱 Event received: type=${response.type}, code=${response.code}');
          
          _handleAddLockKeyEvent(
            response: response,
            onProgress: onProgress,
            onComplete: onComplete,
            onError: onError,
          );
        },
        onError: (error) {
          final errorMsg = _getErrorMessage(error);
          print('❌ Stream error: $errorMsg');
          onError(errorMsg);
        },
      );
    } catch (e) {
      final errorMsg = _getErrorMessage(e);
      print('❌ Failed to start stream: $errorMsg');
      onError(errorMsg);
    }
  }

  /// Handle different event types and make API calls
  void _handleAddLockKeyEvent({
    required AddLockKeyResponse response,
    required Function(AddLockKeyResponse) onProgress,
    required Function(AddLockKeyResponse) onComplete,
    required Function(String) onError,
  }) async {
    switch (response.type) {
      case 'addLockKeyChunk':
        // Progress update (fingerprint enrollment in progress)
        print('⏳ ${response.progressMessage}');
        onProgress(response);
        break;

      case 'addLockKeyDone':
        // Enrollment complete - now make API call to backend
        print('✅ Enrollment complete');
        try {
          final keyObj = response.body['keyObj'] as Map<String, dynamic>?;
          final success = await _uploadKeyToBackend(
            lockMac: response.lockMac,
            keyData: keyObj ?? {},
            authTotal: response.body['authTotal'] ?? 0,
            authCount: response.body['authCount'] ?? 0,
          );
          
          if (success) {
            onComplete(response);
          } else {
            onError('Failed to save key to server');
          }
        } catch (e) {
          onError(_getErrorMessage(e));
        }
        break;

      case 'addLockKeyError':
        // Error occurred
        final errorMsg = response.message.isNotEmpty
            ? response.message
            : response.ackMessage;
        print('❌ $errorMsg');
        onError(errorMsg);
        break;

      default:
        print('⚠️ Unknown event type: ${response.type}');
    }
  }

  /// Make API call to save key to backend
  Future<bool> _uploadKeyToBackend({
    required String lockMac,
    required Map<String, dynamic> keyData,
    required int authTotal,
    required int authCount,
  }) async {
    try {
      print('📤 Uploading key to backend...');
      
      final response = await _dio.post(
        'https://your-api.com/api/lock-keys/add', // Replace with your backend URL
        data: {
          'lockMac': lockMac,
          'keyData': keyData,
          'authTotal': authTotal,
          'authCount': authCount,
          'timestamp': DateTime.now().toIso8601String(),
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer YOUR_TOKEN', // Add your auth token
          },
        ),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('✅ Key saved successfully');
        return true;
      } else {
        print('❌ Server returned ${response.statusCode}');
        return false;
      }
    } on DioException catch (e) {
      print('❌ Network error: ${e.message}');
      return false;
    } catch (e) {
      print('❌ Unexpected error: $e');
      return false;
    }
  }

  /// Convert error codes to user-friendly English messages
  String _getErrorMessage(dynamic error) {
    // Map error codes to English messages
    final errorMap = {
      '0x02': 'Password error',
      '0x03': 'Remote unlocking not enabled',
      '0x04': 'Invalid parameters',
      '0x05': 'Operation not allowed - add administrator first',
      '0x06': 'Operation not supported by lock',
      '0x07': 'Key already exists',
      '0x08': 'Invalid index or number',
      '0x0A': 'System is locked',
      '0x0E': 'Storage full',
      '0xE1': 'Authentication failed',
      '0xE2': 'Device busy, try again later',
      '0xE8': 'Please add the device first',
      '0xFF04': 'Connection timeout',
      '0xFF05': 'Bluetooth disconnected',
      'PERMISSION_DENIED': 'Bluetooth permission required',
      'INIT_ERROR': 'Failed to initialize BLE client',
      'NO_LISTENER': 'Event stream not available',
    };

    if (error is DioException) {
      if (error.type == DioExceptionType.connectionTimeout) {
        return 'Network connection timeout';
      } else if (error.type == DioExceptionType.sendTimeout) {
        return 'Request timeout';
      } else if (error.type == DioExceptionType.receiveTimeout) {
        return 'Response timeout';
      } else if (error.response?.statusCode == 404) {
        return 'Resource not found';
      } else if (error.response?.statusCode == 401) {
        return 'Unauthorized - please login again';
      } else if (error.response?.statusCode == 500) {
        return 'Server error - please try again later';
      }
      return error.message ?? 'Network error occurred';
    }

    // Check for error code matches
    final errorStr = error.toString();
    for (final entry in errorMap.entries) {
      if (errorStr.contains(entry.key)) {
        return entry.value;
      }
    }

    // Default messages
    if (error is String) {
      return errorMap[error] ?? 'Unknown error: $error';
    }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Stop listening to events
  void dispose() {
    _eventSubscription?.cancel();
  }
}
```

### File: `lib/screens/add_key_screen.dart`

```dart
import 'package:flutter/material.dart';
import '../services/lock_key_service.dart';

class AddLockKeyScreen extends StatefulWidget {
  @override
  State<AddLockKeyScreen> createState() => _AddLockKeyScreenState();
}

class _AddLockKeyScreenState extends State<AddLockKeyScreen> {
  final LockKeyService _lockKeyService = LockKeyService();
  String _status = 'Ready to add key';
  bool _isEnrolling = false;
  int _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Add NFC/Fingerprint Key')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Status Display
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey[100],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  Text(
                    _status,
                    style: TextStyle(fontSize: 16),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 12),
                  if (_isEnrolling)
                    LinearProgressIndicator(value: _progress / 100),
                ],
              ),
            ),
            SizedBox(height: 24),

            // Start Button
            ElevatedButton.large(
              onPressed: _isEnrolling ? null : _startEnrollment,
              child: Text(_isEnrolling ? 'Enrolling...' : 'Start Fingerprint Enrollment'),
            ),
          ],
        ),
      ),
    );
  }

  void _startEnrollment() {
    setState(() => _isEnrolling = true);

    _lockKeyService.startAddLockKeyStream(
      lockMac: 'AA:BB:CC:DD:EE:FF', // Replace with actual lock MAC
      dnaAes128Key: 'YOUR_DNA_KEY',  // Replace with actual key
      authorizedRoot: 'YOUR_AUTH_CODE', // Replace with actual code
      addedKeyType: 1, // 1 = fingerprint
      authorMode: 0,
      onProgress: (response) {
        setState(() {
          _status = response.progressMessage ?? 'Enrolling...';
          _progress = (response.body['authCount'] ?? 0).toInt();
        });
      },
      onComplete: (response) {
        setState(() {
          _isEnrolling = false;
          _status = '✅ Key added successfully!';
        });
        _showSuccessDialog();
      },
      onError: (errorMsg) {
        setState(() {
          _isEnrolling = false;
          _status = '❌ Error: $errorMsg';
        });
        _showErrorDialog(errorMsg);
      },
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Success'),
        content: Text('Key added successfully and saved to server.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          )
        ],
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Try Again'),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _lockKeyService.dispose();
    super.dispose();
  }
}
```

---

## 3. Error Message Mapping (No Chinese)

All error messages are mapped to English using the error code from the native response:

| Code | English Message |
|------|-----------------|
| 0x01 | Operation successful |
| 0x02 | Password error |
| 0x03 | Remote unlocking not enabled |
| 0x04 | Invalid parameters |
| 0x05 | Operation not allowed - add administrator first |
| 0x06 | Not supported by lock |
| 0x07 | Key already exists |
| 0x08 | Invalid index number |
| 0x0E | Storage full |
| 0xE1 | Authentication failed |
| 0xE2 | Device busy, try again |
| 0xE8 | Please add device first |
| 0xFF04 | Connection timeout |
| 0xFF05 | Bluetooth disconnected |

---

## 4. Key Points

✅ **Response Flow:** Native → EventChannel → Flutter Code → API Call
✅ **Three Event Types:** `addLockKeyChunk` (progress), `addLockKeyDone` (complete), `addLockKeyError` (error)
✅ **No Chinese:** All error messages converted to English before showing to user
✅ **API Integration:** Backend API call made only after successful enrollment
✅ **Proper Error Handling:** Network errors, timeouts, and SDK errors all handled gracefully
