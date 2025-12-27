package com.example.wise_apartment.utils;

public class RFModuleType {
    /** External 433MHz module */
    public static final int TCV433 = 0;
    /** Not currently in use */
    public static final int LPRX315 = 1;
    /** Not currently in use */
    public static final int TCV868 = 2;
    /** External Wi-Fi module */
    public static final int HXJWIFI = 4;
    /** NB-IoT, can connect directly to network */
    public static final int HXJNBDX = 5;
    /** LoRa module */
    public static final int HXJLoRa = 6;
    /** Not currently in use */
    public static final int HXJZigBee = 7;
    /** Wi-Fi module supporting ID card cloud parsing */
    public static final int HXJWIFIZJJX = 8;
    /** NBIoT module with MQTT Protocol support */
    public static final int HXJNBMQTT = 9;
    /** NBIoT module with LWM2M protocol support */
    public static final int HXJNBLWM2M = 10;
    /** LTEUE-Category1 (Cat.1) module */
    public static final int HXJCat1= 11;
    /** No wireless module */
    public static final int Empty = 255;

}
