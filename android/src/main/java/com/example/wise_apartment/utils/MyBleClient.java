package com.example.wise_apartment.utils;

import android.bluetooth.BluetoothDevice;
import android.content.Context;
import android.util.Log;

import androidx.annotation.NonNull;

import com.example.hxjblinklibrary.blinkble.entity.EventResponse;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAction;
import com.example.hxjblinklibrary.blinkble.entity.reslut.KeyEventAddKey;
import com.example.hxjblinklibrary.blinkble.entity.reslut.KeyEventRegWifi;
import com.example.hxjblinklibrary.blinkble.parser.open.EventPostDataParser;
import com.example.hxjblinklibrary.blinkble.profile.client.FunCallback;
import com.example.hxjblinklibrary.blinkble.profile.client.HxjBleClient;
import com.example.hxjblinklibrary.blinkble.profile.client.LinkCallBack;
import com.example.hxjblinklibrary.blinkble.profile.data.HXData;
import com.example.hxjblinklibrary.blinkble.utils.ByteUtil;

public class MyBleClient extends HxjBleClient {
    private static final String TAG = "MyBleClient";
    private static MyBleClient sInstance;
    private WifiRegistrationCallback wifiCallback;
    private LinkCallBack externalLinkCallBack;

    public interface WifiRegistrationCallback {
        void onWifiRegistrationEvent(int status, String moduleMac, String lockMac);
    }

    public void setWifiRegistrationCallback(WifiRegistrationCallback callback) {
        this.wifiCallback = callback;
    }

    public static MyBleClient getInstance(Context context) {
        if (sInstance == null) {
            synchronized (MyBleClient.class) {
                if (sInstance == null) {
                    sInstance = new MyBleClient(context);
                }
            }
        }
        return sInstance;
    }

    @Override
    public void setLinkCallBack(LinkCallBack callBack) {
        this.externalLinkCallBack = callBack;
    }

    public MyBleClient(Context context) {
        super(context);
        super.setLinkCallBack(new LinkCallBack() {
            @Override
            public void onDeviceConnected(@NonNull BluetoothDevice device) {
                if (externalLinkCallBack != null) externalLinkCallBack.onDeviceConnected(device);
            }

            @Override
            public void onDeviceDisconnected(@NonNull BluetoothDevice device) {
                if (externalLinkCallBack != null) externalLinkCallBack.onDeviceDisconnected(device);
            }

            @Override
            public void onLinkLossOccurred(@NonNull BluetoothDevice device) {
                if (externalLinkCallBack != null) externalLinkCallBack.onLinkLossOccurred(device);
            }

            @Override
            public void onDeviceReady(@NonNull BluetoothDevice device) {
                if (externalLinkCallBack != null) externalLinkCallBack.onDeviceReady(device);
            }

            @Override
            public void onDeviceNotSupported(@NonNull BluetoothDevice device) {
                if (externalLinkCallBack != null) externalLinkCallBack.onDeviceNotSupported(device);
            }

            @Override
            public void onError(@NonNull BluetoothDevice device, @NonNull String message, int errorCode) {
                if (externalLinkCallBack != null) externalLinkCallBack.onError(device, message, errorCode);
            }

            @Override
            public void onEventReport(String substring, int cmdVersion, String lockMac) {
                // Handle WiFi registration events internally first
                EventResponse<String> stringEventResponse = EventPostDataParser.paraseCommon(substring);
                Log.d(TAG, "onEventReport: 日志上报 " + stringEventResponse);
                HXData data = new HXData(ByteUtil.hexStr2Byte(substring));
                Integer eventPower = data.getIntValue(HXData.FORMAT_UINT8, 8);
                switch (stringEventResponse.EventType()) {
                    case EventResponse.KeyEventConstants.LOCK_EVT_OPEN_LOCK:
                        break;
                    case EventResponse.KeyEventConstants.LOCK_EVT_ADD_LOCK_KEY:
                        KeyEventAddKey result = EventPostDataParser.parseAddKey(substring);
                        break;
                    case 0x2D:
                        KeyEventRegWifi wifiReport = EventPostDataParser.parseWifiReg(substring);
                        int wifiStatus = wifiReport.getWifiStatues();
                        if (wifiStatus == 0x02) {
                            Log.d(TAG, "WiFi module network distribution binding in progress");
                        } else if (wifiStatus == 0x04) {
                            Log.d(TAG, "WiFi module successfully connected to router");
                        } else if (wifiStatus == 0x05) {
                            Log.d(TAG, "WiFi module successfully connected to cloud");
                        } else if (wifiStatus == 0x06) {
                            Log.d(TAG, "Incorrect password");
                        } else if (wifiStatus == 0x07) {
                            Log.d(TAG, "WiFi configuration timeout");
                        }

                        String moduleMac = "";
                        try {
                            java.lang.reflect.Field moduleMacField = wifiReport.getClass().getDeclaredField("ModuleMac");
                            moduleMacField.setAccessible(true);
                            Object macValue = moduleMacField.get(wifiReport);
                            if (macValue != null) {
                                moduleMac = macValue.toString();
                            }
                        } catch (Exception e) {
                            Log.w(TAG, "Could not get ModuleMac from wifiReport", e);
                        }

                        if (wifiCallback != null) {
                            Log.d(TAG, "Emitting WiFi registration event: status=" + wifiStatus + ", moduleMac=" + moduleMac + ", lockMac=" + lockMac);
                            wifiCallback.onWifiRegistrationEvent(wifiStatus, moduleMac, lockMac);
                        }
                        break;
                }

                // Delegate to external callback so plugin also gets the event
                if (externalLinkCallBack != null) externalLinkCallBack.onEventReport(substring, cmdVersion, lockMac);
            }
        });
    }

    @Override
    public void disConnectBle(FunCallback funCallback) {
        super.disConnectBle(funCallback);
    }

    @Override
    public void connectBle(BlinkyAction blinkyAction, FunCallback funCallback) {
        super.connectBle(blinkyAction, funCallback);
    }
}
