//
//  HXAddBigDataKeyHelper.m
//  Wise Apartment Plugin
//
//  Helper for adding fingerprint/face biometric keys with chunked BLE transmission
//

#import "HXAddBigDataKeyHelper.h"
#import <HXJBLESDK/HXBluetoothLockHelper.h>

@interface HXAddBigDataKeyHelper ()

@property (nonatomic, assign) BOOL isCancel;
@property (nonatomic, strong) NSData *keyData;
@property (nonatomic, copy) NSString *lockMac;
@property (nonatomic, assign) int keyGroupId;
@property (nonatomic, copy) BLESendBigKeyDataBlock progressBlock;
@property (nonatomic, assign) KSHKeyType curKeyType;
@property (nonatomic, assign) KSHBLESendBigKeyDataPhase curPhase;
@property (nonatomic, assign) NSInteger lastStatusCode;
@property (nonatomic, strong) SHBLEAddBigDataKeyParam *param;
@property (nonatomic, assign) int maxBlockSize;
@property (nonatomic, assign) int lockKeyId;
@property (nonatomic, strong) HXKeyModel *tempKeyObj;
@property (nonatomic, strong) SHBLEKeyValidTimeParam *timeParam;

@end

@implementation HXAddBigDataKeyHelper

- (instancetype)init {
    self = [super init];
    if (self) {
        self.maxBlockSize = 200;
    }
    return self;
}

- (void)startWithBigDataBase64Str:(NSString *)bigDataBase64Str
                          lockMac:(NSString *)lockMac
                       keyGroupId:(int)keyGroupId
                          keyType:(KSHKeyType)keyType
                        timeParam:(SHBLEKeyValidTimeParam *)timeParam
                    progressBlock:(BLESendBigKeyDataBlock)progressBlock {
    
    self.curKeyType = keyType;
    self.progressBlock = progressBlock;
    self.lockMac = lockMac;
    self.keyGroupId = keyGroupId;
    self.timeParam = timeParam;
    
    // Decode Base64 string to NSData
    self.keyData = [[NSData alloc] initWithBase64EncodedString:bigDataBase64Str options:0];
    
    if (!self.keyData || self.keyData.length == 0) {
        if (progressBlock) {
            progressBlock(KSHStatusCode_Failed, @"Invalid Base64 data", KSHBLESendBigKeyDataPhase_end, 0, nil);
        }
        return;
    }
    
    [self start];
}

- (void)start {
    _isCancel = NO;
    self.lockKeyId = 0;
    
    self.param = [[SHBLEAddBigDataKeyParam alloc] init];
    self.param.totalBytesLength = (int)self.keyData.length;
    self.param.currentIndex = 0;
    int totalNum = (int)(self.keyData.length / self.maxBlockSize) + ((self.keyData.length % self.maxBlockSize) == 0 ? 0 : 1);
    self.param.totalNum = totalNum;
    self.param.keyGroupId = self.keyGroupId;
    
    if (self.progressBlock) {
        self.curPhase = KSHBLESendBigKeyDataPhase_sending;
        self.lastStatusCode = KSHStatusCode_Success;
        self.progressBlock(KSHStatusCode_Success, @"Preparing to send key data...", KSHBLESendBigKeyDataPhase_sending, 0, nil);
    }
    
    [self recursionSendKeyData];
}

- (void)cancel {
    _isCancel = YES;
    self.progressBlock = nil;
    self.keyData = nil;
    self.timeParam = nil;
    self.lockKeyId = 0;
    [NSObject cancelPreviousPerformRequestsWithTarget:self];
}

- (void)recursionSendKeyData {
    if (_isCancel) {
        return;
    }
    
    NSInteger currentBytes = self.param.currentIndex * self.maxBlockSize;
    NSRange range = NSMakeRange(currentBytes, self.maxBlockSize);
    
    if ((currentBytes + self.maxBlockSize) > self.param.totalBytesLength) {
        range.length = (self.param.totalBytesLength - currentBytes);
        NSLog(@"[HXAddBigDataKeyHelper] Sending final packet %d/%d", self.param.currentIndex, self.param.totalNum);
    } else {
        NSLog(@"[HXAddBigDataKeyHelper] Sending packet %d/%d", self.param.currentIndex, self.param.totalNum);
    }
    
    NSData *sendData = [self.keyData subdataWithRange:range];
    self.param.data = sendData;
    
    __weak typeof(self) weakSelf = self;
    
    if (self.curKeyType == KSHKeyType_Face) {
        [HXBluetoothLockHelper addFaceKeyDataParam:self.param
                                          timeParam:self.timeParam
                                            lockMac:self.lockMac
                                    completionBlock:^(KSHStatusCode statusCode, NSString *reason, NSInteger currentIndex, int lockKeyId) {
            [weakSelf onBLEAddKeyDataResponse:statusCode reason:reason currentIndex:currentIndex lockKeyId:lockKeyId];
        }];
    } else if (self.curKeyType == KSHKeyType_Fingerprint) {
        [HXBluetoothLockHelper addFingerprintKeyDataParam:self.param
                                                timeParam:self.timeParam
                                                   locMac:self.lockMac
                                          completionBlock:^(KSHStatusCode statusCode, NSString *reason, NSInteger currentIndex, int lockKeyId) {
            [weakSelf onBLEAddKeyDataResponse:statusCode reason:reason currentIndex:currentIndex lockKeyId:lockKeyId];
        }];
    }
}

- (void)onBLEAddKeyDataResponse:(KSHStatusCode)statusCode
                         reason:(NSString *)reason
                   currentIndex:(NSInteger)currentIndex
                      lockKeyId:(int)lockKeyId {
    
    if (statusCode == KSHStatusCode_Success) {
        self.param.currentIndex++;
        self.curPhase = KSHBLESendBigKeyDataPhase_sending;
        
        if (self.progressBlock) {
            CGFloat progress = (self.param.currentIndex * 1.0) / self.param.totalNum;
            
            if (self.param.currentIndex == self.param.totalNum) {
                progress = 0.98; // Wait for final confirmation before setting to 1.0
            }
            
            NSLog(@"[HXAddBigDataKeyHelper] Progress: %.0f%% (%d/%d)",
                  progress * 100, self.param.currentIndex, self.param.totalNum);
            
            self.lastStatusCode = KSHStatusCode_Success;
            self.progressBlock(KSHStatusCode_Success, @"Sending key data...", self.curPhase, progress, nil);
        }
        
        if (self.param.currentIndex == self.param.totalNum) {
            // All packets sent successfully
            self.lockKeyId = lockKeyId;
            
            if (self.progressBlock) {
                self.curPhase = KSHBLESendBigKeyDataPhase_end;
                self.lastStatusCode = KSHStatusCode_Success;
                [self setupKeyObj];
                self.progressBlock(self.lastStatusCode, @"Key added successfully", self.curPhase, 1.0, self.tempKeyObj);
            }
        } else {
            // Continue sending next packet
            [self recursionSendKeyData];
        }
    } else {
        // Error occurred
        if (self.progressBlock) {
            self.isCancel = YES;
            self.curPhase = KSHBLESendBigKeyDataPhase_sending;
            CGFloat progress = (self.param.currentIndex * 1.0) / self.param.totalNum;
            
            NSString *tips = [NSString stringWithFormat:@"Failed to add key: %@", reason ?: @"Unknown error"];
            self.lastStatusCode = statusCode;
            self.progressBlock(statusCode, tips, self.curPhase, progress, nil);
        }
    }
}

- (void)setupKeyObj {
    if (!_tempKeyObj) {
        _tempKeyObj = [[HXKeyModel alloc] init];
    }
    
    _tempKeyObj.lockMac = self.lockMac;
    _tempKeyObj.keyGroupId = self.keyGroupId;
    _tempKeyObj.lockKeyId = self.lockKeyId;
    _tempKeyObj.keyType = self.curKeyType;
    _tempKeyObj.updateTime = [[NSDate date] timeIntervalSince1970];
    _tempKeyObj.validStartTime = self.timeParam.validStartTime;
    _tempKeyObj.validEndTime = self.timeParam.validEndTime;
    _tempKeyObj.validNumber = self.timeParam.vaildNumber;
    _tempKeyObj.authMode = self.timeParam.authMode;
    _tempKeyObj.weeks = self.timeParam.weeks;
    _tempKeyObj.dayStartTimes = self.timeParam.dayStartTimes;
    _tempKeyObj.dayEndTimes = self.timeParam.dayEndTimes;
}

@end
