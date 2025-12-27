package com.example.wise_apartment.utils;

import android.util.Log;

import com.example.hxjblinklibrary.blinkble.profile.client.IHxBleSecureAuth;

import java.io.BufferedReader;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.net.HttpURLConnection;
import java.net.URL;

/**
 * Minimal port of SecureAuthHelper for plugin usage.
 */
public class SecureAuthHelper implements IHxBleSecureAuth {

    private static final String TAG = "SecureAuthHelper";
    private static String lockDNAAESKey = "Ytg6hpwXyF5OS329";

    @Override
    public void getSessionIdCmd(int keyGroupId, int snr, String lockMac, RequestComplection complection) {

        new Thread(() -> {
            String urlStr = "http://192.168.31.148/sessionEncode?keyGroupId=" + keyGroupId + "&" + "snr=" + snr + "&" + "aesKey=" + lockDNAAESKey;
            Log.d(TAG, "Send url: " + urlStr);
            try {
                URL url = new URL(urlStr);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(15 * 1000);
                if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                    InputStream inputStream = connection.getInputStream();
                    String sessionIdCmd = inputStreamToString(inputStream);
                    Log.d(TAG, "getSessionIdCmd: " + sessionIdCmd);
                    if (complection != null) {
                        complection.callback(sessionIdCmd);
                    }
                } else {
                    callbackFailed(complection);
                }
            } catch (Exception e) {
                e.printStackTrace();
                callbackFailed(complection);
            }
        }).start();
    }

    @Override
    public void parseSessionId(String lockMac, String sessionIdPlayload, RequestComplection complection) {
        new Thread(() -> {

            String urlStr = "http://192.168.31.148/sessionDecode?payload=" + sessionIdPlayload + "&" + "aesKey=" + lockDNAAESKey;
            Log.d(TAG, "Send url: " + urlStr);
            try {
                URL url = new URL(urlStr);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(15 * 1000);
                if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                    InputStream inputStream = connection.getInputStream();
                    String sessionId = inputStreamToString(inputStream);
                    Log.d(TAG, "parseSessionId: " + sessionId);
                    if (complection != null) {
                        complection.callback(sessionId);
                    }
                } else {
                    callbackFailed(complection);
                }
            } catch (Exception e) {
                e.printStackTrace();
                callbackFailed(complection);
            }
        }).start();
    }

    @Override
    public void getAESKeyCmd(int keyGroupId, int snr, String sessionId, String lockMac, RequestComplection complection) {
        new Thread(() -> {

            String urlStr = "http://192.168.31.148/secretKeyEncode?keyGroupId=" + keyGroupId + "&" + "snr=" + snr + "&" + "aesKey=" + lockDNAAESKey + "&" + "sessionId=" + sessionId;
            Log.d(TAG, "Send url: " + urlStr);

            try {
                URL url = new URL(urlStr);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(15 * 1000);

                if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                    InputStream inputStream = connection.getInputStream();
                    String aesKeyCmd = inputStreamToString(inputStream);
                    Log.d(TAG, "getAESKeyCmd: " + aesKeyCmd);
                    if (complection != null) {
                        complection.callback(aesKeyCmd);
                    }
                } else {
                    callbackFailed(complection);
                }
            } catch (Exception e) {
                e.printStackTrace();
                callbackFailed(complection);
            }
        }).start();
    }

    @Override
    public void parseAESKey(String lockMac, String aesKeyPlayload, RequestComplection complection) {
        new Thread(() -> {

            String urlStr = "http://192.168.31.148/secretKeyDecode?payload=" + aesKeyPlayload + "&" + "aesKey=" + lockDNAAESKey;
            Log.d(TAG, "Send url: " + urlStr);

            try {
                URL url = new URL(urlStr);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(15 * 1000);
                if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                    InputStream inputStream = connection.getInputStream();
                    String dynaseKey = inputStreamToString(inputStream);
                    Log.d(TAG, "parseAESKey: " + dynaseKey);
                    if (complection != null) {
                        complection.callback(dynaseKey);
                    }
                } else {
                    callbackFailed(complection);
                }
            } catch (Exception e) {
                e.printStackTrace();
                callbackFailed(complection);
            }
        }).start();
    }

    @Override
    public void getAuthCmd(int keyGroupId, int snr, String sessionId, String aesKey, String lockMac, RequestComplection complection) {
        new Thread(() -> {

            String urlStr = "http://192.168.31.148/authenticationEncode?keyGroupId=" + keyGroupId + "&" + "snr=" + snr + "&" + "aes128Key=" + aesKey + "&" + "sessionId=" + sessionId + "&" + "authCode=" + "14399F8A";
            Log.d(TAG, "Send url: " + urlStr);

            try {
                URL url = new URL(urlStr);
                HttpURLConnection connection = (HttpURLConnection) url.openConnection();
                connection.setRequestMethod("GET");
                connection.setConnectTimeout(15 * 1000);
                if (connection.getResponseCode() == HttpURLConnection.HTTP_OK) {
                    InputStream inputStream = connection.getInputStream();
                    String authCmd = inputStreamToString(inputStream);
                    Log.d(TAG, "getAuthCmd: " + authCmd);
                    if (complection != null) {
                        complection.callback(authCmd);
                    }
                } else {
                    callbackFailed(complection);
                }
            } catch (Exception e) {
                e.printStackTrace();
                callbackFailed(complection);
            }
        }).start();
    }

    private void callbackFailed(RequestComplection complection) {
        Log.d(TAG, "Request Failed");

        if (complection != null) {
            complection.callback(null);
        }
    }

    private String inputStreamToString(InputStream inputStream) {
        String str = null;
        try {
            BufferedReader r = new BufferedReader(new InputStreamReader(inputStream));
            StringBuilder total = new StringBuilder();
            for (String line; (line = r.readLine()) != null; ) {
                total.append(line).append('\n');
            }
            str = total.toString();
            str = str.replace("\n", "");
        } catch (Exception e) {
            e.printStackTrace();
        }
        return str;
    }
}
