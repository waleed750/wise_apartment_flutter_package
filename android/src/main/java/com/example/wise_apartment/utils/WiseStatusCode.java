package com.example.wise_apartment.utils;

import java.util.HashMap;
import java.util.Map;

public final class WiseStatusCode {
    private WiseStatusCode() {}

    public static final int ACK_STATUS_SUCCESS = 0x01; // Operation successful
    public static final int ACK_STATUS_PASSWORD_ERR = 0x02; // Password error
    public static final int ACK_STATUS_REMOTE_NOT_ALLOWED = 0x03; // Remote unlocking not enabled
    public static final int ACK_STATUS_PARAM_ERR = 0x04; // Parameter error
    public static final int ACK_STATUS_OPERATE_NOT_ALLOWED = 0x05; // Prohibit this operation, please add an administrator first
    public static final int ACK_STATUS_OPERATE_UNSUPPORT = 0x06; // The door lock does not support this operation or command
    public static final int ACK_STATUS_ADD_REPEAT = 0x07; // Repeat adding (cards/passwords, etc.)
    public static final int ACK_STATUS_INDEX_ERR = 0x08; // Number error
    public static final int ACK_STATUS_OPEN_LOCK_NOT_ALLOWED = 0x09; // Do not allow reverse locking
    public static final int ACK_STATUS_SYS_LOCKED = 0x0A; // System is locked
    public static final int ACK_STATUS_DEL_ADMIN_ERR = 0x0B; // Prohibit deleting administrators
    public static final int ACK_STATUS_FULL_ERR = 0x0E; // Storage full
    public static final int ACK_STATUS_PACKET_FOLLWOED = 0x0F; // Follow-up data packets available
    public static final int ACK_STATUS_NEXT = 0x10; // Door locked, cannot open/unlock
    public static final int ACK_STATUS_ADD_KEY_EXIT = 0x11; // Exit and add key
    public static final int ACK_STATUS_RF_BUSY = 0x23; // RF module busy
    public static final int ACK_STATUS_OPEN_LOCKING = 0x2B; // Electronic lock engaged
    public static final int ACK_STATUS_AUTH_ERR = 0xE1; // Authentication failed
    public static final int ACK_STATUS_BUSY = 0xE2; // Device busy, try again later
    public static final int ACK_STATUS_ENC_TYPE_ERR = 0xE4; // Incorrect encryption type
    public static final int ACK_STATUS_SESSION_ID_ERR = 0xE5; // Session ID incorrect
    public static final int ACK_STATUS_NOT_PAIRING = 0xE6; // Device not in pairing mode
    public static final int ACK_STATUS_CMD_NOT_ALLOWED = 0xE7; // Command not allowed
    public static final int ACK_STATUS_PAIRING_ERR = 0xE8; // Please add the device first
    public static final int ACK_STATUS_PAIR_REPEAT = 0xEA; // Already has permission
    public static final int ACK_STATUS_INSUFF_PERMISSION = 0xEB; // Insufficient permissions
    public static final int ACK_STATUS_INVALID_CMD_VERSION = 0xEC; // Invalid command version / protocol mismatch
    public static final int LOCAL_STATUS_DNA_NULL = 0xFF00; // DNA key empty
    public static final int LOCAL_SESSION_ID_REC_NULL = 0xFF01; // Session ID empty
    public static final int LOCAL_AES_FUN_KEY_REC_NULL = 0xFF02; // AES KEY empty
    public static final int LOCAL_AUTH_CODE_NULL = 0xFF03; // Authentication code empty
    public static final int LOCAL_SCAN_TIME_OUT = 0xFF04; // Scan/connection timeout
    public static final int LOCAL_DIS_CONNECT = 0xFF05; // Bluetooth disconnected
    public static final int LOCAL_DECRYPT_ERR = 0xFF07; // Decryption failed

    public static String description(int code) {
        switch (code) {
            case ACK_STATUS_SUCCESS: return "Operation successful";
            case ACK_STATUS_PASSWORD_ERR: return "Password error";
            case ACK_STATUS_REMOTE_NOT_ALLOWED: return "Remote unlocking not enabled";
            case ACK_STATUS_PARAM_ERR: return "Parameter error";
            case ACK_STATUS_OPERATE_NOT_ALLOWED: return "Operation prohibited (add administrator first)";
            case ACK_STATUS_OPERATE_UNSUPPORT: return "Operation not supported by lock";
            case ACK_STATUS_ADD_REPEAT: return "Repeat adding (already exists)";
            case ACK_STATUS_INDEX_ERR: return "Index/number error";
            case ACK_STATUS_OPEN_LOCK_NOT_ALLOWED: return "Reverse locking not allowed";
            case ACK_STATUS_SYS_LOCKED: return "System is locked";
            case ACK_STATUS_DEL_ADMIN_ERR: return "Prohibit deleting administrators";
            case ACK_STATUS_FULL_ERR: return "Storage full";
            case ACK_STATUS_PACKET_FOLLWOED: return "Follow-up data packets available";
            case ACK_STATUS_NEXT: return "Door locked, cannot open/unlock";
            case ACK_STATUS_ADD_KEY_EXIT: return "Exit and add key status";
            case ACK_STATUS_RF_BUSY: return "RF module busy";
            case ACK_STATUS_OPEN_LOCKING: return "Electronic lock engaged (unlock not allowed)";
            case ACK_STATUS_AUTH_ERR: return "Authentication failed";
            case ACK_STATUS_BUSY: return "Device busy, try again later";
            case ACK_STATUS_ENC_TYPE_ERR: return "Incorrect encryption type";
            case ACK_STATUS_SESSION_ID_ERR: return "Session ID incorrect";
            case ACK_STATUS_NOT_PAIRING: return "Device not in pairing mode";
            case ACK_STATUS_CMD_NOT_ALLOWED: return "Command not allowed";
            case ACK_STATUS_PAIRING_ERR: return "Please add the device first (pairing error)";
            case ACK_STATUS_PAIR_REPEAT: return "Already has permission (pair repeat)";
            case ACK_STATUS_INSUFF_PERMISSION: return "Insufficient permissions";
            case ACK_STATUS_INVALID_CMD_VERSION: return "Invalid command version / protocol mismatch";
            case LOCAL_STATUS_DNA_NULL: return "DNA key empty";
            case LOCAL_SESSION_ID_REC_NULL: return "Session ID empty";
            case LOCAL_AES_FUN_KEY_REC_NULL: return "AES key empty";
            case LOCAL_AUTH_CODE_NULL: return "Authentication code empty";
            case LOCAL_SCAN_TIME_OUT: return "Scan/connection timeout";
            case LOCAL_DIS_CONNECT: return "Bluetooth disconnected";
            case LOCAL_DECRYPT_ERR: return "Decryption failed";
            default: return "Unknown status code: 0x" + Integer.toHexString(code).toUpperCase();
        }
    }

    public static Map<String, Object> toMap(int code) {
        Map<String, Object> m = new HashMap<>();
        m.put("code", code);
        m.put("ackMessage", description(code));
        return m;
    }

    public static boolean isSuccess(int code) {
        return code == ACK_STATUS_SUCCESS;
    }
}
