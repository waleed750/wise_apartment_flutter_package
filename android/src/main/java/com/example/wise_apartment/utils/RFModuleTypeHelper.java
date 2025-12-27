package com.example.wise_apartment.utils;


public class RFModuleTypeHelper {

    public static boolean isHXJNBIoTRFType(int rfType) {
        if (rfType == RFModuleType.HXJNBDX ||
                rfType == RFModuleType.HXJNBMQTT ||
                rfType == RFModuleType.HXJNBLWM2M) {
            return true;
        }
        return false;
    }

    public static boolean isHXJWiFiRFType(int rfType) {
        if (rfType == RFModuleType.HXJWIFI ||
                rfType == RFModuleType.HXJWIFIZJJX) {
            return true;
        }
        return false;
    }

    public static boolean isCat1RFType(int rfType) {
        if (rfType == RFModuleType.HXJCat1) {
            return true;
        }
        return false;
    }

}
