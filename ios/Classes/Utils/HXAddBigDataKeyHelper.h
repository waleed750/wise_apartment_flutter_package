//
//  HXAddBigDataKeyHelper.h
//  Wise Apartment Plugin
//
//  Helper for adding fingerprint/face biometric keys with chunked BLE transmission
//

#import <Foundation/Foundation.h>
#import <HXJBLESDK/HXKeyModel.h>
#import <HXJBLESDK/SHBLEKeyValidTimeParam.h>

NS_ASSUME_NONNULL_BEGIN

typedef NS_ENUM(NSInteger, KSHBLESendBigKeyDataPhase) {
    /**
     Sending data packets - check progress percentage
     */
    KSHBLESendBigKeyDataPhase_sending = 0,
    /**
     Key data sent successfully
     */
    KSHBLESendBigKeyDataPhase_end,
};

typedef void(^BLESendBigKeyDataBlock)(NSInteger statusCode, NSString * _Nullable reason, KSHBLESendBigKeyDataPhase phase, CGFloat progress, HXKeyModel *__nullable keyObj);

@interface HXAddBigDataKeyHelper : NSObject

/// Start adding fingerprint/face key to lock
/// - Parameters:
///   - bigDataBase64Str: Fingerprint/face feature data (Base64 encoded)
///   - lockMac: Lock MAC address
///   - keyGroupId: User ID for this key (range: 900-4095)
///   - keyType: Key type (KSHKeyType_Fingerprint or KSHKeyType_Face)
///   - timeParam: Key validity period parameters
///   - progressBlock: Progress callback
- (void)startWithBigDataBase64Str:(NSString *)bigDataBase64Str
                          lockMac:(NSString *)lockMac
                       keyGroupId:(int)keyGroupId
                          keyType:(KSHKeyType)keyType
                        timeParam:(SHBLEKeyValidTimeParam *)timeParam
                    progressBlock:(BLESendBigKeyDataBlock)progressBlock;

/// Cancel operation
- (void)cancel;

@end

NS_ASSUME_NONNULL_END
