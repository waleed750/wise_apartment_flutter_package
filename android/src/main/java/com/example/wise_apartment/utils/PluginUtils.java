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
        // Support two input shapes:
        // 1) auth map with keys: authCode, dnaKey, mac, keyGroupId, bleProtocolVer
        // 2) dna info map produced by DnaInfoModel.toMap() with keys like
        //    'authorizedRoot', 'dnaAes128Key', 'mac', 'protocolVer', etc.

        // authCode: prefer explicit authCode, otherwise look for authorizedRoot
        v = args.get("authCode");
        if (v instanceof String) builder.authCode((String) v);
        else {
            v = args.get("authorizedRoot");
            if (v instanceof String) builder.authCode((String) v);
        }

        // dnaKey: prefer explicit dnaKey, otherwise look for dnaAes128Key
        v = args.get("dnaKey");
        if (v instanceof String) builder.dnaKey((String) v);
        else {
            v = args.get("dnaAes128Key");
            if (v instanceof String) builder.dnaKey((String) v);
        }

        // mac is common in both shapes
        v = args.get("mac");
        if (v instanceof String) builder.mac((String) v);

        if (args.containsKey("keyGroupId")) {
            v = args.get("keyGroupId");
            if (v instanceof Integer) builder.keyGroupId((Integer) v);
            else if (v instanceof String) {
                try { builder.keyGroupId(Integer.parseInt((String) v)); } catch (Exception ignored) {}
            }
        }

        // bleProtocolVer: explicit key or from dna map 'protocolVer'
        if (args.containsKey("bleProtocolVer") || args.containsKey("protocolVer")) {
            v = args.containsKey("bleProtocolVer") ? args.get("bleProtocolVer") : args.get("protocolVer");
            if (v instanceof Integer) builder.bleProtocolVer((Integer) v);
            else if (v instanceof String) {
                try { builder.bleProtocolVer(Integer.parseInt((String) v)); } catch (Exception ignored) {}
            }
        }

        return builder.build();
    }
}
