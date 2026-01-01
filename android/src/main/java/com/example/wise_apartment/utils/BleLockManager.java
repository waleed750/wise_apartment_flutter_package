package com.example.wise_apartment.utils;

import android.util.Log;
import java.util.Map;

import io.flutter.plugin.common.MethodChannel.Result;
import com.example.hxjblinklibrary.blinkble.profile.client.HxjBleClient;
import com.example.hxjblinklibrary.blinkble.profile.client.FunCallback;
import com.example.hxjblinklibrary.blinkble.entity.Response;
import com.example.hxjblinklibrary.blinkble.entity.reslut.HxBLEUnlockResult;
import com.example.hxjblinklibrary.blinkble.entity.reslut.DnaInfo;
import com.example.hxjblinklibrary.blinkble.entity.reslut.SysParamResult;
import com.example.hxjblinklibrary.blinkble.profile.data.common.StatusCode;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.OpenLockAction;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAction;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BleSetHotelLockSystemAction;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BleHotelLockSystemParam;
import java.util.HashMap;

public class BleLockManager {
    private static final String TAG = "BleLockManager";
    private final HxjBleClient bleClient;

    // Helper: convert vendor Response<?> to stable Map<String,Object>
    private Map<String, Object> responseToMap(Response<?> response, Object bodyObj) {
        Map<String, Object> m = new HashMap<>();
        if (response == null) return m;
        int codeVal = -1;
        try { codeVal = response.code(); m.put("code", codeVal); } catch (Throwable ignored) {}
        try {
            String msg = null;
            try { msg = response.message(); } catch (Throwable t) { msg = null; }
            m.put("message", msg);
        } catch (Throwable ignored) {}
        try { m.put("ackMessage", ackMessageForCode(codeVal)); } catch (Throwable ignored) {}
        try { m.put("isSuccessful", response.isSuccessful()); } catch (Throwable ignored) {}
        try { m.put("isError", response.isError()); } catch (Throwable ignored) {}
        try { m.put("lockMac", response.getLockMac()); } catch (Throwable ignored) {}

        // body conversion
        if (bodyObj != null) {
            m.put("body", bodyObj);
        } else {
            try {
                Object body = response.body();
                if (body == null) {
                    m.put("body", null);
                } else if (body instanceof DnaInfo) {
                    m.put("body", dnaInfoToMap((DnaInfo) body));
                } else if (body instanceof SysParamResult) {
                    m.put("body", sysParamToMap((SysParamResult) body));
                } else if (body instanceof HxBLEUnlockResult) {
                    try { m.put("body", body.toString()); } catch (Throwable t) { m.put("body", null); }
                } else {
                    try { m.put("body", body.toString()); } catch (Throwable t) { m.put("body", null); }
                }
            } catch (Throwable ignored) { m.put("body", null); }
        }

        return m;
    }

    private Map<String, Object> dnaInfoToMap(DnaInfo dna) {
        Map<String, Object> m = new HashMap<>();
        if (dna == null) return m;
        try { m.put("mac", dna.getMac()); } catch (Throwable ignored) {}
        try { m.put("protocolVer", dna.getProtocolVer()); } catch (Throwable ignored) {}
        try { m.put("authorizedRoot", dna.getAuthorizedRoot()); } catch (Throwable ignored) {}
        try { m.put("dnaAes128Key", dna.getDnaAes128Key()); } catch (Throwable ignored) {}
        // Include native/server payload string if available
        try { m.put("deviceDnaInfoStr", dna.getDeviceDnaInfoStr()); } catch (Throwable ignored) {}
        // Try to include other helpful fields if present in vendor class
        try { m.put("deviceType", dna.getDeviceType()); } catch (Throwable ignored) {}
        try { m.put("hardware", dna.getHardWareVer()); } catch (Throwable ignored) {}
        try { m.put("software", dna.getSoftWareVer()); } catch (Throwable ignored) {}
        try { m.put("rFModuleType", dna.getrFMoudleType()); } catch (Throwable ignored) {}
        try { m.put("rFModuleMac", dna.getRFModuleMac()); } catch (Throwable ignored) {}
        return m;
    }

    private Map<String, Object> sysParamToMap(SysParamResult s) {
        Map<String, Object> m = new HashMap<>();
        if (s == null) return m;
        try { m.put("raw", s.toString()); } catch (Throwable ignored) {}
        try { m.put("deviceStatusStr", s.getDeviceStatusStr()); } catch (Throwable ignored) {}
        return m;
    }

    // Map numeric ACK/status codes to human-readable messages
    private String ackMessageForCode(int code) {
        switch (code) {
            case 0x01: return "Operation successful";
            case 0x02: return "Password error";
            case 0x03: return "Remote unlocking not enabled";
            case 0x04: return "Parameter error";
            case 0x05: return "Operation prohibited (add administrator first)";
            case 0x06: return "Operation not supported by lock";
            case 0x07: return "Repeat adding (already exists)";
            case 0x08: return "Index/number error";
            case 0x09: return "Reverse locking not allowed";
            case 0x0A: return "System is locked";
            case 0x0B: return "Prohibit deleting administrators";
            case 0x0E: return "Storage full";
            case 0x0F: return "Follow-up data packets available";
            case 0x10: return "Door locked, cannot open/unlock";
            case 0x11: return "Exit and add key status";
            case 0x23: return "RF module busy";
            case 0x2B: return "Electronic lock engaged (unlock not allowed)";
            case 0xE1: return "Authentication failed";
            case 0xE2: return "Device busy, try again later";
            case 0xE4: return "Incorrect encryption type";
            case 0xE5: return "Session ID incorrect";
            case 0xE6: return "Device not in pairing mode";
            case 0xE7: return "Command not allowed";
            case 0xE8: return "Please add the device first (pairing error)";
            case 0xEA: return "Already has permission (pair repeat)";
            case 0xEB: return "Insufficient permissions";
            case 0xEC: return "Invalid command version / protocol mismatch";
            case 0xFF00: return "DNA key empty";
            case 0xFF01: return "Session ID empty";
            case 0xFF02: return "AES key empty";
            case 0xFF03: return "Authentication code empty";
            case 0xFF04: return "Scan/connection timeout";
            case 0xFF05: return "Bluetooth disconnected";
            case 0xFF07: return "Decryption failed";
            default:
                return "Unknown status code: 0x" + Integer.toHexString(code).toUpperCase();
        }
    }

    public BleLockManager(HxjBleClient client) {
        this.bleClient = client;
    }

    public void openLock(Map<String, Object> args, final Result result) {
        Log.d(TAG, "openLock called with args: " + args);
        OpenLockAction action = new OpenLockAction();
        action.setBaseAuthAction(PluginUtils.createAuthAction(args));
        
        bleClient.openLock(action, new FunCallback<HxBLEUnlockResult>() {
            @Override
            public void onResponse(Response<HxBLEUnlockResult> response) {
                Log.d(TAG, "openLock response: " + response.code());
                if (response.isSuccessful()) {
                    result.success(true);
                } else {
                    result.error("FAILED", "Code: " + response.code(), null);
                }
                bleClient.disConnectBle(null); // Disconnect after operation as per original logic
            }

            @Override
            public void onFailure(Throwable t) {
                Log.e(TAG, "openLock failed", t);
                result.error("ERROR", t.getMessage(), null);
                bleClient.disConnectBle(null);
            }
        });
    }

    public void closeLock(Map<String, Object> args, final Result result) {
        Log.d(TAG, "closeLock called");
        BlinkyAction action = new BlinkyAction();
        action.setBaseAuthAction(PluginUtils.createAuthAction(args));
        
        bleClient.closeLock(action, new FunCallback<Object>() {
            @Override
            public void onResponse(Response<Object> response) {
                 Log.d(TAG, "closeLock response: " + response.code());
                 if (response.isSuccessful()) result.success(true);
                 else result.error("FAILED", "Code: " + response.code(), null);
            }
            @Override
            public void onFailure(Throwable t) {
                Log.e(TAG, "closeLock failed", t);
                result.error("ERROR", t.getMessage(), null);
            }
        });
    }

    public void setKeyExpirationAlarmTime(Map<String, Object> args, final Result result) {
        Log.d(TAG, "setKeyExpirationAlarmTime called");
        int time = (int) args.get("time");
        
        BleSetHotelLockSystemAction action = new BleSetHotelLockSystemAction();
        BleHotelLockSystemParam param = new BleHotelLockSystemParam();
        param.setExpirationAlarmTime(time);
        action.setParam(param);
        action.setBaseAuthAction(PluginUtils.createAuthAction(args));
        
        bleClient.bleSetHotelLockSystemParam(action, new FunCallback<Object>() {
            @Override
            public void onResponse(Response<Object> response) {
                if (response.isSuccessful()) result.success(true);
                else result.error("FAILED", "Code: " + response.code(), null);
            }
            @Override
            public void onFailure(Throwable t) {
                 result.error("ERROR", t.getMessage(), null);
            }
        });
    }

    public void deleteLock(Map<String, Object> args, final Result result) {
        Log.d(TAG, "deleteLock called");
        BlinkyAction action = new BlinkyAction();
        action.setBaseAuthAction(PluginUtils.createAuthAction(args));
        
        bleClient.delDevice(action, new FunCallback<String>() {
            @Override
            public void onResponse(Response<String> response) {
                bleClient.disConnectBle(null);
                if (response.isSuccessful()) result.success(true);
                else result.error("FAILED", "Code: " + response.code(), null);
            }
            @Override
            public void onFailure(Throwable t) {
                bleClient.disConnectBle(null);
                result.error("ERROR", t.getMessage(), null);
            }
        });
    }

    public void getDna(Map<String, Object> args, final Result result) {
        Log.d(TAG, "getDna called");
        BlinkyAction action = new BlinkyAction();
        action.setBaseAuthAction(PluginUtils.createAuthAction(args));
        
        bleClient.getDna(action, new FunCallback<DnaInfo>() {
            @Override
            public void onResponse(Response<DnaInfo> response) {
                if (response.isSuccessful() && response.body() != null) {
                    Map<String, Object> res = new HashMap<>();
                    DnaInfo dna = response.body();
                    res.put("mac", dna.getMac());
                    result.success(res);
                } else {
                     result.error("FAILED", "Code: " + response.code(), null);
                }
            }
            @Override
            public void onFailure(Throwable t) {
                 result.error("ERROR", t.getMessage(), null);
            }
        });
    }

    /**
     * Add device (orchestrates the sample app flow):
     * 1) addDevice -> receives DnaInfo
     * 2) build base auth action and call getSysParam
     * 3) on success call pairSuccessInd and rfModulePairing
     */
    public void addDevice(Map<String, Object> args, final Result result) {
        Log.d(TAG, "addDevice called with args: " + args);
        // Try to build the BlinkyAuthAction from `mac` (Method 2 in sample app).
        // If `mac` is not provided, fall back to PluginUtils.createAuthAction(args).
        final com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction auth;

        String mac = null;
        if (args != null && args.containsKey("mac")) {
            Object m = args.get("mac");
            if (m instanceof String) mac = (String) m;
        }

        if (mac != null && !mac.isEmpty()) {
            auth = new com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction.Builder()
                    .mac(mac)
                    .build();
        } else {
            auth = com.example.wise_apartment.utils.PluginUtils.createAuthAction(args);
        }

        int chipType = 0;
        if (args != null && args.containsKey("chipType")) {
            Object v = args.get("chipType");
            if (v instanceof Integer) chipType = (Integer) v;
            else if (v instanceof String) {
                try { chipType = Integer.parseInt((String) v); } catch (Exception ignored) {}
            }
        }

        bleClient.addDevice(auth, chipType, new FunCallback<DnaInfo>() {
            @Override
            public void onResponse(Response<DnaInfo> response) {
                Map<String, Object> finalMap = new HashMap<>();
                Map<String, Object> responses = new HashMap<>();

                // addDevice response
                Map<String, Object> addDeviceMap = responseToMap(response, null);
                responses.put("addDevice", addDeviceMap);

                if (!response.isSuccessful() || response.body() == null) {
                    finalMap.put("ok", false);
                    finalMap.put("stage", "addDevice");
                    finalMap.put("responses", responses);
                    finalMap.put("dnaInfo", null);
                    finalMap.put("sysParam", null);
                    result.success(finalMap);
                    return;
                }

                DnaInfo dna = response.body();
                Log.d(TAG, "addDevice got DnaInfo: " + dna.getMac());

                Map<String, Object> dnaMap = dnaInfoToMap(dna);
                // Debug: log key DNA fields used to build auth and pairing
                try {
                    Log.d(TAG, "dnaMap: " + dnaMap);
                } catch (Throwable ignored) {}
                try { Log.d(TAG, "dna.dnaAes128Key present: " + (dna.getDnaAes128Key() != null)); } catch (Throwable ignored) {}
                try { Log.d(TAG, "dna.protocolVer: " + dna.getProtocolVer()); } catch (Throwable ignored) {}
                try { Log.d(TAG, "dna.authorizedRoot: " + dna.getAuthorizedRoot()); } catch (Throwable ignored) {}
                try { Log.d(TAG, "dna.mac: " + dna.getMac()); } catch (Throwable ignored) {}
                try { Log.d(TAG, "dna.deviceDnaInfoStr: " + dna.getDeviceDnaInfoStr()); } catch (Throwable ignored) {}
                // overwrite addDevice body with dna map
                responses.put("addDevice", responseToMap(response, dnaMap));
                Log.d(TAG,dna.getMac() + " AddDevice success, proceeding to getSysParam");
                // Build base auth action from dna info
                com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction baseAuth = new com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction.Builder()
                        .bleProtocolVer(dna.getProtocolVer())
                        .authCode(dna.getAuthorizedRoot())
                        .dnaKey(dna.getDnaAes128Key())
                        .mac(dna.getMac())
                        .keyGroupId(900)
                        .build();

                BlinkyAction action = new BlinkyAction();
                action.setBaseAuthAction(baseAuth);

                try {
                    bleClient.getSysParam(action, new FunCallback<SysParamResult>() {
                        @Override
                        public void onResponse(Response<SysParamResult> resp) {
                            Map<String, Object> finalMap2 = new HashMap<>();
                            Map<String, Object> responses2 = responses;

                            // Map getSysParam response once and extract body
                            Map<String, Object> sysMap = responseToMap(resp, null);
                            responses2.put("getSysParam", sysMap);

                            // Follow native flow: require explicit ACK_STATUS_SUCCESS
                            if (resp.code() != StatusCode.ACK_STATUS_SUCCESS || resp.body() == null) {
                                finalMap2.put("ok", false);
                                finalMap2.put("stage", "getSysParam");
                                finalMap2.put("responses", responses2);
                                finalMap2.put("dnaInfo", dnaMap);
                                finalMap2.put("sysParam", null);
                                try { finalMap2.put("message", ackMessageForCode(resp.code())); } catch (Throwable ignored) {}
                                result.success(finalMap2);
                                return;
                            }

                            // sysParam body map and capture deviceStatusObj like native sample
                            Map<String, Object> sysBody = null;
                            final SysParamResult deviceStatusObj = resp.body();
                            try {
                                if (deviceStatusObj != null) {
                                    sysBody = sysParamToMap(deviceStatusObj);
                                    try { Log.d(TAG, "deviceStatusStr: " + deviceStatusObj.getDeviceStatusStr()); } catch (Throwable ignored) {}
                                }
                            } catch (Throwable ignored) { sysBody = null; }

                            // pairSuccessInd
                            try {
                                bleClient.pairSuccessInd(action, true, new FunCallback() {
                                    @Override
                                    public void onResponse(Response pairResp) {
                                        // always disconnect after pair attempt
                                        bleClient.disConnectBle(null);

                                        Map<String, Object> finalMap3 = new HashMap<>();
                                        Map<String, Object> responses3 = responses2;

                                        Map<String, Object> pairMap = responseToMap(pairResp, null);
                                        responses3.put("pairSuccessInd", pairMap);

                                        try { Log.d(TAG, "pairSuccessInd code: " + pairResp.code() + " pairMap: " + pairMap); } catch (Throwable ignored) {}

                                        // default rfModulePairing null
                                        responses3.put("rfModulePairing", null);

                                        if (pairResp.isSuccessful()) {
                                            // attempt rfModulePairing but do not fail flow if it fails
                                            try {
                                                // Non-blocking: start rfModulePairing and mark started; do not wait for result
                                                responses3.put("rfModulePairing", null);
                                                finalMap3.put("rfModulePairingStarted", true);
                                                bleClient.rfModulePairing(action, "", new FunCallback() {
                                                    @Override
                                                    public void onResponse(Response rfResp) {
                                                        try {
                                                            Map<String, Object> rfMap = responseToMap(rfResp, null);
                                                            responses3.put("rfModulePairing", rfMap);
                                                            Log.d(TAG, "rfModulePairing response: " + rfResp.code());
                                                        } catch (Throwable ignored) {}
                                                    }

                                                    @Override
                                                    public void onFailure(Throwable throwable) {
                                                        try {
                                                            Map<String, Object> rfMap = new HashMap<>();
                                                            rfMap.put("error", throwable.getMessage());
                                                            responses3.put("rfModulePairing", rfMap);
                                                            Log.d(TAG, "rfModulePairing failure: " + throwable.getMessage());
                                                        } catch (Throwable ignored) {}
                                                    }
                                                });
                                            } catch (Exception ignored) {}

                                            finalMap3.put("ok", true);
                                            finalMap3.put("stage", "pairSuccessInd");
                                            finalMap3.put("responses", responses3);
                                            finalMap3.put("dnaInfo", dnaMap);
                                            finalMap3.put("sysParam", responseToMap(resp, null).get("body") != null ? responseToMap(resp, null).get("body") : null);
                                            result.success(finalMap3);
                                        } else {
                                            finalMap3.put("ok", false);
                                            finalMap3.put("stage", "pairSuccessInd");
                                            finalMap3.put("responses", responses3);
                                            finalMap3.put("dnaInfo", dnaMap);
                                            finalMap3.put("sysParam", responseToMap(resp, null).get("body") != null ? responseToMap(resp, null).get("body") : null);
                                            result.success(finalMap3);
                                        }
                                    }

                                    @Override
                                    public void onFailure(Throwable t) {
                                        Log.e(TAG, "pairSuccessInd failed", t);
                                        result.error("ERROR", t.getMessage(), null);
                                    }
                                });
                            } catch (Exception e) {
                                Log.e(TAG, "Exception during pairSuccessInd", e);
                                result.error("ERROR", e.getMessage(), null);
                            }
                        }

                        @Override
                        public void onFailure(Throwable t) {
                            Log.e(TAG, "getSysParam failed", t);
                            result.error("ERROR", t.getMessage(), null);
                        }
                    });
                } catch (Exception e) {
                    Log.e(TAG, "Exception during addDevice flow", e);
                    result.error("ERROR", e.getMessage(), null);
                }
            }

            @Override
            public void onFailure(Throwable t) {
                Log.e(TAG, "addDevice failed", t);
                result.error("ERROR", t.getMessage(), null);
            }
        });
    }

    /**
     * Notify device that pairing succeeded on the server side.
     * Expects `args` to contain the auth fields used by PluginUtils.createAuthAction.
     */
    public void pairSuccessInd(Map<String, Object> args, final Result result) {
        Log.d(TAG, "pairSuccessInd called with args: " + args);
        BlinkyAction hxBleAction = new BlinkyAction();
        hxBleAction.setBaseAuthAction(PluginUtils.createAuthAction(args));

        bleClient.pairSuccessInd(hxBleAction, true, new FunCallback() {
            @Override
            public void onResponse(Response response) {
                // Disconnect first to allow future scans
                bleClient.disConnectBle(null);

                Map<String, Object> out = new HashMap<>();
                Map<String, Object> respMap = responseToMap(response, null);
                out.put("ok", response.isSuccessful());
                out.put("response", respMap);

                // attempt rfModulePairing but do not treat failure as overall error
                try {
                    bleClient.rfModulePairing(hxBleAction, "", new FunCallback() {
                        @Override
                        public void onResponse(Response rfResp) {
                            try { out.put("rfModulePairing", responseToMap(rfResp, null)); } catch (Throwable ignored) {}
                        }

                        @Override
                        public void onFailure(Throwable throwable) {
                            try { Map<String,Object> rfMap = new HashMap<>(); rfMap.put("error", throwable.getMessage()); out.put("rfModulePairing", rfMap); } catch (Throwable ignored) {}
                        }
                    });
                } catch (Exception ignored) {}

                result.success(out);
            }

            @Override
            public void onFailure(Throwable t) {
                Log.e(TAG, "pairSuccessInd failed", t);
                result.error("ERROR", t.getMessage(), null);
            }
        });
    }
}
