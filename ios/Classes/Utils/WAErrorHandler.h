//
//  WAErrorHandler.h
//  wise_apartment
//
//  Centralized error handling and Flutter error conversion
//

#import <Foundation/Foundation.h>
#import <Flutter/Flutter.h>

NS_ASSUME_NONNULL_BEGIN

// Error codes (1000-1999 range for consistency with Android)
typedef NS_ENUM(NSInteger, WAErrorCode) {
    WAErrorCodeBluetoothUnavailable = 1001,
    WAErrorCodeScanAlreadyRunning = 1002,
    WAErrorCodeBluetoothOff = 1003,
    WAErrorCodePermissionDenied = 1004,
    
    WAErrorCodeDeviceNotFound = 1010,
    WAErrorCodePairingFailed = 1011,
    WAErrorCodePairingCancelled = 1012,
    WAErrorCodePairingTimeout = 1013,
    
    WAErrorCodeServerRegistrationFailed = 1020,
    WAErrorCodeNetworkError = 1021,
    
    WAErrorCodeWiFiConfigFailed = 1030,
    WAErrorCodeWiFiConfigTimeout = 1031,
    WAErrorCodeInvalidSSID = 1032,
    
    WAErrorCodeInvalidParameters = 1040,
    WAErrorCodeSDKError = 1050,
    WAErrorCodeUnknown = 1099
};

@interface WAErrorHandler : NSObject

/**
 * Create FlutterError from error code and message
 */
+ (FlutterError *)flutterErrorWithCode:(WAErrorCode)code
                               message:(NSString *)message
                               details:(nullable id)details;

/**
 * Convert NSError to FlutterError
 */
+ (FlutterError *)flutterErrorFromNSError:(NSError *)error;

/**
 * Create NSError with WAErrorCode
 */
+ (NSError *)errorWithCode:(WAErrorCode)code
                   message:(NSString *)message;

/**
 * Get user-friendly message for error code
 */
+ (NSString *)messageForErrorCode:(WAErrorCode)code;

@end

NS_ASSUME_NONNULL_END
