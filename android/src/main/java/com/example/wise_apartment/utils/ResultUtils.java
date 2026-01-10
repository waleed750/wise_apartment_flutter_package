package com.example.wise_apartment.utils;

import android.util.Log;
import java.util.HashMap;
import java.util.Map;
import io.flutter.plugin.common.MethodChannel.Result;

public final class ResultUtils {
    private static final String TAG = "ResultUtils";

    private ResultUtils() {}

    /**
     * Reply with an error, attaching a details Map that includes numeric status
     * `code` and optional `ackMessage` when provided.
     */
    public static void errorWithCode(Result result, String code, String message, Integer numericCode, String ackMessage) {
        try {
            Map<String, Object> details = new HashMap<>();
            if (numericCode != null) details.put("code", numericCode);
            if (ackMessage != null) details.put("ackMessage", ackMessage);
            result.error(code, message, details);
        } catch (Throwable t) {
            Log.w(TAG, "reply errorWithCode failed", t);
            try { result.error(code, message, null); } catch (Throwable ignore) {}
        }
    }

    public static void errorWithRawDetails(Result result, String code, String message, Map<String, Object> details) {
        try {
            result.error(code, message, details);
        } catch (Throwable t) {
            Log.w(TAG, "reply errorWithRawDetails failed", t);
            try { result.error(code, message, null); } catch (Throwable ignore) {}
        }
    }
}
