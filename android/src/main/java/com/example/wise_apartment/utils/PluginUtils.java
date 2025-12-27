package com.example.wise_apartment.utils;

import java.util.Map;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction;

public class PluginUtils {
    /**
     * Helper to create BlinkyAuthAction from MethodChannel arguments.
     */
    public static BlinkyAuthAction createAuthAction(Map<String, Object> args) {
        BlinkyAuthAction.Builder builder = new BlinkyAuthAction.Builder();

        if (args == null) return builder.build();

        Object v;
        v = args.get("authCode");
        if (v instanceof String) builder.authCode((String) v);

        v = args.get("dnaKey");
        if (v instanceof String) builder.dnaKey((String) v);

        v = args.get("mac");
        if (v instanceof String) builder.mac((String) v);

        if (args.containsKey("keyGroupId")) {
            v = args.get("keyGroupId");
            if (v instanceof Integer) builder.keyGroupId((Integer) v);
            else if (v instanceof String) {
                try { builder.keyGroupId(Integer.parseInt((String) v)); } catch (Exception ignored) {}
            }
        }

        if (args.containsKey("bleProtocolVer")) {
            v = args.get("bleProtocolVer");
            if (v instanceof Integer) builder.bleProtocolVer((Integer) v);
            else if (v instanceof String) {
                try { builder.bleProtocolVer(Integer.parseInt((String) v)); } catch (Exception ignored) {}
            }
        }

        return builder.build();
    }
}
