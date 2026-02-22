package com.example.wise_apartment.utils;

import android.content.Context;
import android.os.Handler;
import android.util.Base64;
import android.util.Log;

import com.example.hxjblinklibrary.blinkble.entity.Response;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BLEAddBigDataKeyAction;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BLEKeyValidTimeParam;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction;
import com.example.hxjblinklibrary.blinkble.entity.reslut.BleLockAddFaceKeyResult;
import com.example.hxjblinklibrary.blinkble.entity.reslut.LockKeyResult;
import com.example.hxjblinklibrary.blinkble.profile.client.FunCallback;
import com.example.hxjblinklibrary.blinkble.profile.client.HxjBleClient;
import com.example.hxjblinklibrary.blinkble.profile.data.common.KeyType;
import com.example.hxjblinklibrary.blinkble.profile.data.common.StatusCode;
import com.example.hxjblinklibrary.blinkble.utils_2.TimeUtils;

import java.util.HashMap;
import java.util.Map;

/**
 * Helper class for adding big data keys (fingerprint/face) to smart locks.
 * Handles chunking of Base64 data into 180-byte packets and streaming progress.
 */
public class AddBigDataKeyHelper {
    private static final String TAG = "AddBigDataKeyHelper";
    private static final int MAX_BLOCK_SIZE = 180;
    
    private final Context context;
    private final HxjBleClient bleClient;
    
    private boolean isCancel;
    private byte[] keyBytes;
    private String lockMac;
    private int keyGroupId;
    private int curKeyType;
    private BlinkyAuthAction baseAuthObj;
    private BLEKeyValidTimeParam timeParam;
    private BLEAddBigDataKeyAction param;
    private Handler timeoutHandler;
    private int lockKeyId;
    private SendBigKeyDataCallback progressCallback;
    
    public interface SendBigKeyDataCallback {
        void onProgress(int statusCode, String message, int phase, double progress);
        void onComplete(int statusCode, String message, LockKeyResult keyResult);
        void onError(int statusCode, String message);
    }
    
    public AddBigDataKeyHelper(Context context, HxjBleClient bleClient) {
        this.context = context;
        this.bleClient = bleClient;
    }
    
    /**
     * Start adding big data key (fingerprint/face) to lock.
     */
    public void startWithBigDataBase64Str(String bigDataBase64Str,
                                          String lockMac,
                                          int keyGroupId,
                                          int keyType,
                                          BLEKeyValidTimeParam timeParam,
                                          BlinkyAuthAction baseAuthObj,
                                          SendBigKeyDataCallback callback) {
        Log.d(TAG, "startWithBigDataBase64Str: keyType=" + keyType + ", keyGroupId=" + keyGroupId);
        
        this.progressCallback = callback;
        this.lockMac = lockMac;
        this.keyGroupId = keyGroupId;
        this.curKeyType = keyType;
        this.timeParam = timeParam;
        this.baseAuthObj = baseAuthObj;
        
        // Decode Base64 data
        String error = decodeBase64Str(bigDataBase64Str);
        if (error != null) {
            if (callback != null) {
                callback.onError(StatusCode.ACK_STATUS_PARAM_ERR, error);
            }
            return;
        }
        
        start();
    }
    
    private String decodeBase64Str(String base64Str) {
        if (base64Str == null || base64Str.isEmpty()) {
            return "Fingerprint data is empty";
        }
        
        try {
            keyBytes = Base64.decode(base64Str, Base64.NO_WRAP);
            Log.d(TAG, "Decoded " + keyBytes.length + " bytes from Base64");
            return null;
        } catch (IllegalArgumentException e) {
            return "Invalid Base64 data: " + e.getMessage();
        }
    }
    
    private void start() {
        isCancel = false;
        lockKeyId = 0;
        
        param = new BLEAddBigDataKeyAction();
        param.setBaseAuthAction(baseAuthObj);
        param.totalBytesLength = keyBytes.length;
        param.currentIndex = 0;
        int totalNum = (keyBytes.length / MAX_BLOCK_SIZE) + ((keyBytes.length % MAX_BLOCK_SIZE) == 0 ? 0 : 1);
        param.totalNum = totalNum;
        param.keyGroupId = keyGroupId;
        
        if (progressCallback != null) {
            progressCallback.onProgress(StatusCode.ACK_STATUS_SUCCESS, 
                "Preparing to send " + totalNum + " packets", 0, 0.0);
        }
        
        recursionSendKeyData();
    }
    
    private void recursionSendKeyData() {
        if (isCancel) {
            return;
        }
        
        int currentIndex = param.currentIndex * MAX_BLOCK_SIZE;
        int length = MAX_BLOCK_SIZE;
        
        if (currentIndex + MAX_BLOCK_SIZE > param.totalBytesLength) {
            length = param.totalBytesLength - currentIndex;
            Log.d(TAG, "Sending final packet " + param.currentIndex + "/" + param.totalNum);
        } else {
            Log.d(TAG, "Sending packet " + param.currentIndex + "/" + param.totalNum);
        }
        
        byte[] sendData = new byte[length];
        System.arraycopy(keyBytes, currentIndex, sendData, 0, length);
        param.data = sendData;
        
        if (curKeyType == KeyType.Face) {
            bleClient.addFaceKeyData(param, timeParam, new FunCallback() {
                @Override
                public void onResponse(Response response) {
                    onBLEAddKeyDataResponse(response);
                }
                @Override
                public void onFailure(Throwable t) {
                    onBLEFailure(t);
                }
            });
        } else if (curKeyType == KeyType.FINGER) {
            bleClient.addFingerprintKeyData(param, timeParam, new FunCallback() {
                @Override
                public void onResponse(Response response) {
                    onBLEAddKeyDataResponse(response);
                }
                @Override
                public void onFailure(Throwable t) {
                    onBLEFailure(t);
                }
            });
        }
    }
    
    private void onBLEAddKeyDataResponse(Response response) {
        int statusCode = response.code();
        
        if (statusCode == StatusCode.ACK_STATUS_SUCCESS) {
            if (response.body() instanceof BleLockAddFaceKeyResult) {
                BleLockAddFaceKeyResult result = (BleLockAddFaceKeyResult) response.body();
                
                if (result.flags == 0 && result.currentIndex == result.totalNum) {
                    // Last packet received, waiting for final confirmation (flags==1)
                    startTimeoutForFinalPacket();
                    return;
                }
                
                removeTimeoutHandler();
                onBLEResponseSuccess(result.lockKeyId);
            }
        } else {
            String reason = WiseStatusCode.description(statusCode);
            String tips = "Failed to add key: " + reason;
            onBLEResponseFailed(statusCode, tips);
        }
    }
    
    private void onBLEResponseSuccess(int lockKeyId) {
        param.currentIndex++;
        double progress = (param.currentIndex * 1.0) / param.totalNum;
        
        if (param.currentIndex == param.totalNum) {
            progress = 0.98; // Almost done, waiting for final confirmation
        }
        
        Log.d(TAG, "Progress: " + (int)(progress * 100) + "% (" + param.currentIndex + "/" + param.totalNum + ")");
        
        if (progressCallback != null) {
            String message = "Sending packet " + param.currentIndex + "/" + param.totalNum;
            progressCallback.onProgress(StatusCode.ACK_STATUS_SUCCESS, message, 1, progress);
        }
        
        if (param.currentIndex == param.totalNum) {
            this.lockKeyId = lockKeyId;
            LockKeyResult keyObj = setupKeyObj();
            
            if (progressCallback != null) {
                progressCallback.onComplete(StatusCode.ACK_STATUS_SUCCESS, 
                    "Fingerprint added successfully", keyObj);
            }
        } else {
            recursionSendKeyData();
        }
    }
    
    private void onBLEResponseFailed(int statusCode, String reason) {
        double progress = (param.currentIndex * 1.0) / param.totalNum;
        
        if (progressCallback != null) {
            isCancel = true;
            progressCallback.onError(statusCode, reason);
        }
    }
    
    private void onBLEFailure(Throwable t) {
        String reason = t.getMessage();
        int statusCode = StatusCode.ACK_STATUS_FAIL;
        
        if (progressCallback != null) {
            progressCallback.onError(statusCode, "BLE failure: " + reason);
        }
    }
    
    private void startTimeoutForFinalPacket() {
        if (timeoutHandler == null) {
            timeoutHandler = new Handler();
        }
        
        timeoutHandler.postDelayed(new Runnable() {
            @Override
            public void run() {
                if (progressCallback != null) {
                    progressCallback.onError(StatusCode.LOCAL_SCAN_TIME_OUT, 
                        "Timeout waiting for final confirmation");
                }
            }
        }, 15000); // 15 second timeout
    }
    
    private void removeTimeoutHandler() {
        if (timeoutHandler != null) {
            timeoutHandler.removeCallbacksAndMessages(null);
            timeoutHandler = null;
        }
    }
    
    private LockKeyResult setupKeyObj() {
        LockKeyResult keyObj = new LockKeyResult();
        keyObj.setKeyID(this.lockKeyId);
        keyObj.setKeyType(curKeyType);
        keyObj.setModifyTimestamp(TimeUtils.getNowMills() / 1000);
        keyObj.setVaildStartTime(timeParam.validStartTime);
        keyObj.setVaildEndTime(timeParam.validEndTime);
        keyObj.setVaildNumber(timeParam.validNumber);
        keyObj.setVaildMode(timeParam.authMode);
        keyObj.setWeeks(timeParam.weeks);
        keyObj.setDayStartTimes(timeParam.dayStartTimes);
        keyObj.setDayEndTimes(timeParam.dayEndTimes);
        keyObj.setDeleteMode(1);
        return keyObj;
    }
    
    public void cancel() {
        isCancel = true;
        progressCallback = null;
        keyBytes = null;
        lockKeyId = 0;
        removeTimeoutHandler();
    }
}
