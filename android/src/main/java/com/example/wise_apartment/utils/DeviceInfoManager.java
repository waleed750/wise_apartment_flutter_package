package com.example.wise_apartment.utils;

import android.content.Context;
import android.content.pm.PackageInfo;
import android.content.pm.PackageManager;
import android.os.Build;
import android.util.Log;

import java.util.HashMap;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel.Result;
import com.example.hxjblinklibrary.blinkble.profile.client.HxjBleClient;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction;
import com.example.hxjblinklibrary.blinkble.profile.other.ATConfigHelper;
import com.example.hxjblinklibrary.blinkble.profile.other.Cat1ATConfigHelper;
import com.example.wise_apartment.BuildConfig;

public class DeviceInfoManager {
    private static final String TAG = "DeviceInfoManager";
    private final Context context;
    private final HxjBleClient bleClient;

    public DeviceInfoManager(Context context, HxjBleClient client) {
        this.context = context;
        this.bleClient = client;
    }

    public void getDeviceInfo(Result result) {
        Map<String, Object> info = new HashMap<>();
        info.put("manufacturer", Build.MANUFACTURER);
        info.put("model", Build.MODEL);
        info.put("brand", Build.BRAND);
        info.put("sdkInt", Build.VERSION.SDK_INT);
        info.put("release", Build.VERSION.RELEASE);
        info.put("packageName", context.getPackageName());
        result.success(info);
    }

    public void getAndroidBuildConfig(Result result) {
        Map<String, Object> config = new HashMap<>();
        try {
            // Avoid referencing generated BUILD_* fields which may not exist in this module.
            PackageInfo pInfo = context.getPackageManager().getPackageInfo(context.getPackageName(), 0);
            config.put("applicationId", context.getPackageName());
            config.put("namespace", context.getPackageName());
            config.put("versionName", pInfo.versionName);
            config.put("versionCode", pInfo.versionCode);

            // targetSdk is available from ApplicationInfo; minSdk/compileSdk are not reliably
            // available at runtime across all Android/Gradle setups — provide safe fallbacks.
            config.put("targetSdk", context.getApplicationInfo().targetSdkVersion);

            int minSdk = -1;
            try {
                // try to read minSdkVersion reflectively if present
                java.lang.reflect.Field f = context.getApplicationInfo().getClass().getField("minSdkVersion");
                minSdk = f.getInt(context.getApplicationInfo());
            } catch (Exception ignored) {
            }
            config.put("minSdk", minSdk);
            config.put("compileSdk", -1);
        } catch (Exception e) {
            Log.e(TAG, "Error reading app info", e);
            config.put("error", "Info missing or parse error: " + e.getMessage());
        }
        result.success(config);
    }

    public void getNBIoTInfo(Map<String, Object> args, final Result result) {
        Log.d(TAG, "getNBIoTInfo called");
        BlinkyAuthAction auth = PluginUtils.createAuthAction(args);
       
        ATConfigHelper helper = new ATConfigHelper(context, bleClient);
        helper.startSetting(auth, new ATConfigHelper.ATCallBack() {
            @Override
            public void onAtGetSuccess(int rssi, String imsi, String imei) {
                Map<String, Object> res = new HashMap<>();
                res.put("rssi", rssi);
                res.put("imsi", imsi);
                res.put("imei", imei);
                result.success(res);
            }
            @Override
            public void onError(String s) {
                Log.e(TAG, "getNBIoTInfo error: " + s);
                result.error("ERROR", s, null);
            }
        });
    }

    public void getCat1Info(Map<String, Object> args, final Result result) {
        Log.d(TAG, "getCat1Info called");
        BlinkyAuthAction auth = PluginUtils.createAuthAction(args);
       
        Cat1ATConfigHelper helper = new Cat1ATConfigHelper(context, bleClient);
        helper.start(auth, new Cat1ATConfigHelper.Cat1ATCallBack() {
            @Override
            public void onAtGetSuccess(String iccid, String imei, String imsi, String rssi, String rsrp, String sinr) {
                Map<String, Object> res = new HashMap<>();
                res.put("iccid", iccid);
                res.put("imei", imei);
                res.put("imsi", imsi);
                res.put("rssi", rssi);
                res.put("rsrp", rsrp);
                res.put("sinr", sinr);
                result.success(res);
            }
            @Override
            public void onError(String s) {
                Log.e(TAG, "getCat1Info error: " + s);
                result.error("ERROR", s, null);
            }
        });
    }
}
