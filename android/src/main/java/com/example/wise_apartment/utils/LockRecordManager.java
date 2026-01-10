package com.example.wise_apartment.utils;

import android.util.Log;

import java.lang.reflect.Field;
import java.lang.reflect.Modifier;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.util.concurrent.atomic.AtomicBoolean;

import io.flutter.plugin.common.MethodChannel.Result;
import com.example.hxjblinklibrary.blinkble.profile.client.HxjBleClient;
import com.example.hxjblinklibrary.blinkble.profile.client.FunCallback;
import com.example.hxjblinklibrary.blinkble.entity.Response;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAction;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.BlinkyAuthAction;
import com.example.hxjblinklibrary.blinkble.entity.requestaction.SyncLockRecordAction;
import com.example.hxjblinklibrary.blinkble.entity.reslut.LockRecordDataResult;
import com.example.hxjblinklibrary.blinkble.entity.reslut.lockrecord1.HXRecordBaseModel;
import com.example.hxjblinklibrary.blinkble.entity.reslut.lockrecord2.HXRecord2BaseModel;

public class LockRecordManager {
    private static final String TAG = "LockRecordManager";
    private final HxjBleClient bleClient;

    // State for recursion
    private int currentSyncIndex = 0;
    private int totalSyncRecords = 0;
    private List<Map<String, Object>> syncLogList = new ArrayList<>();
    private Result syncResult;
    private final AtomicBoolean syncReplied = new AtomicBoolean(false);
    private BlinkyAuthAction syncAuth;
    private int syncLogVersion;

    public LockRecordManager(HxjBleClient client) {
        this.bleClient = client;
    }

    public void syncLockRecords(Map<String, Object> args, final Result result) {
        Log.d(TAG, "syncLockRecords called");
        syncAuth = PluginUtils.createAuthAction(args);
        // Prefer explicit caller-provided logVersion. If missing, infer
        // generation from `menuFeature` (third bit == 1 => gen2 only).
        syncLogVersion = 1;
        Object lvObj = args.get("logVersion");
        if (lvObj instanceof Number) {
            syncLogVersion = ((Number) lvObj).intValue();
        } else {
            Object mf = args.get("menuFeature");
            if (mf instanceof Number) {
                int menuFeature = ((Number) mf).intValue();
                // third bit -> mask 0x4
                if ((menuFeature & 0x4) != 0) {
                    syncLogVersion = 2;
                } else {
                    syncLogVersion = 1;
                }
            }
        }
        if (syncLogVersion != 1 && syncLogVersion != 2) {
            syncLogVersion = 1;
        }
        syncResult = result;
        syncReplied.set(false);
        syncLogList.clear();

        BlinkyAction action = new BlinkyAction();
        action.setBaseAuthAction(syncAuth);
//         bleClient.syncLockRecord(
//                 new SyncLockRecordAction(),
//                 new FunCallback<LockRecordDataResult>() {
//                     @Override
//                     public void onResponse(Response<LockRecordDataResult> response) {
//
//                     }
//
//                     @Override
//                     public void onFailure(Throwable throwable) {
//
//                     }
//                 }
//         );
        bleClient.getRecordNum(action, new FunCallback<Integer>() {
            @Override
            public void onResponse(Response<Integer> response) {
                if (response.isSuccessful() && response.body() != null) {
                    totalSyncRecords = response.body();
                    Log.d(TAG, "Total records to sync: " + totalSyncRecords);
                    currentSyncIndex = 0;
                    recursiveQueryRecords();
                    } else {
                    Log.e(TAG, "Failed to get record num: " + response.code());
                    if (syncReplied.compareAndSet(false, true)) {
                        try {
                                    Map<String, Object> details = new HashMap<>();
                                    details.put("code", response.code());
                                    details.put("ackMessage", WiseStatusCode.description(response.code()));
                            result.error("FAILED", "Get Record Num Failed: " + response.code(), details);
                        } catch (Throwable t) {
                            result.error("FAILED", "Get Record Num Failed: " + response.code(), null);
                        }
                    } else {
                        Log.w(TAG, "GetRecordNum failure ignored: reply already sent");
                    }
                }
            }
            @Override
            public void onFailure(Throwable t) {
                Log.e(TAG, "Failed to get record num", t);
                if (syncReplied.compareAndSet(false, true)) {
                    try {
                        Map<String, Object> details = new HashMap<>();
                        details.put("error", t.getMessage());
                        result.error("ERROR", t.getMessage(), details);
                    } catch (Throwable x) {
                        result.error("ERROR", t.getMessage(), null);
                    }
                } else {
                    Log.w(TAG, "GetRecordNum onFailure ignored: reply already sent");
                }
            }
        });
    }

    /**
     * Fetch a single page of lock records without recursively loading all
     * available data. This is useful for callers that want to page through
     * history for performance reasons.
     *
     * Expected args:
     *  - auth fields (for PluginUtils.createAuthAction)
     *  - "logVersion" (1 or 2)
     *  - "startNum" (int, starting index, default 0)
     *  - "readCnt" (int, batch size, default 10)
     *
     * Response is a Map with:
     *  - "total" (int): total records on the lock
     *  - "nextIndex" (int): next index to request, or current start if none
     *  - "hasMore" (bool): whether more data is available
     *  - "records" (List<Map<String, Object>>): mapped records for this page
     */
    public void syncLockRecordsPage(Map<String, Object> args, final Result result) {
        Log.d(TAG, "syncLockRecordsPage called");
        final BlinkyAuthAction auth = PluginUtils.createAuthAction(args);

        // Accept explicit logVersion, otherwise infer from `menuFeature`.
        int logVersion = 1;
        Object lv = args.get("logVersion");
        if (lv instanceof Number) {
            logVersion = ((Number) lv).intValue();
        } else {
            Object mf = args.get("menuFeature");
            if (mf instanceof Number) {
                int menuFeature = ((Number) mf).intValue();
                if ((menuFeature & 0x4) != 0) {
                    logVersion = 2;
                } else {
                    logVersion = 1;
                }
            }
        }
        if (logVersion != 1 && logVersion != 2) logVersion = 1;

        final int startNum = args.containsKey("startNum")
                ? (int) args.get("startNum")
                : 0;
        final int readCnt = args.containsKey("readCnt")
                ? (int) args.get("readCnt")
                : 10;

        BlinkyAction countAction = new BlinkyAction();
        countAction.setBaseAuthAction(auth);

        int finalLogVersion = logVersion;
        final AtomicBoolean replied = new AtomicBoolean(false);
        bleClient.getRecordNum(countAction, new FunCallback<Integer>() {
            @Override
            public void onResponse(Response<Integer> response) {
                if (!response.isSuccessful() || response.body() == null) {
                    Log.e(TAG, "Failed to get record num (paged): " + response.code());
                    if (replied.compareAndSet(false, true)) {
                        try {
                            Map<String, Object> details = new HashMap<>();
                            details.put("code", response.code());
                            details.put("ackMessage", "" + response.code());
                            result.error("FAILED", "Get Record Num Failed: " + response.code(), details);
                        } catch (Throwable t) {
                            result.error("FAILED", "Get Record Num Failed: " + response.code(), null);
                        }
                    } else {
                        Log.w(TAG, "Paged getRecordNum failure ignored: reply already sent");
                    }
                    return;
                }

                int total = response.body();
                Log.d(TAG, "Total records (paged): " + total);

                SyncLockRecordAction recordAction = new SyncLockRecordAction(startNum, readCnt, finalLogVersion);
                recordAction.setBaseAuthAction(auth);

                bleClient.syncLockRecord(recordAction, new FunCallback<LockRecordDataResult>() {
                    @Override
                    public void onResponse(Response<LockRecordDataResult> pageResponse) {
                        if (!pageResponse.isSuccessful() || pageResponse.body() == null) {
                            Log.e(TAG, "Sync page failed at index " + startNum
                                    + " code: " + pageResponse.code());
                            if (replied.compareAndSet(false, true)) {
                                try {
                                    Map<String, Object> details = new HashMap<>();
                                    details.put("code", pageResponse.code());
                                    details.put("ackMessage", WiseStatusCode.description(pageResponse.code()));
                                    result.error("FAILED", "Sync Failed: " + pageResponse.code(), details);
                                } catch (Throwable t) {
                                    result.error("FAILED", "Sync Failed: " + pageResponse.code(), null);
                                }
                            } else {
                                Log.w(TAG, "Paged sync page failure ignored: reply already sent");
                            }
                            return;
                        }

                        LockRecordDataResult body = pageResponse.body();
                        List<Map<String, Object>> records = new ArrayList<>();

                        if (body.getLogNum() > 0) {
                            if (finalLogVersion == 1) {
                                for (HXRecordBaseModel r : body.getLog1Array()) {
                                    Map<String, Object> m = mapRecord(r);
                                    m.put("logVersion", 1);
                                    records.add(m);
                                }
                            } else {
                                for (HXRecord2BaseModel r : body.getLog2Array()) {
                                    Map<String, Object> m = mapRecord(r);
                                    m.put("logVersion", 2);
                                    records.add(m);
                                }
                            }
                        }

                        int nextIndex = startNum + body.getLogNum();
                        boolean hasMore = body.isMoreData() && nextIndex < total;

                        Map<String, Object> out = new HashMap<>();
                        out.put("total", total);
                        out.put("nextIndex", hasMore ? nextIndex : startNum);
                        out.put("hasMore", hasMore);
                        out.put("records", records);

                        if (replied.compareAndSet(false, true)) {
                            result.success(out);
                        } else {
                            Log.w(TAG, "Paged sync success ignored: reply already sent");
                        }
                    }

                    @Override
                    public void onFailure(Throwable t) {
                        Log.e(TAG, "Sync page failed exception", t);
                        if (replied.compareAndSet(false, true)) {
                            try {
                                Map<String, Object> details = new HashMap<>();
                                details.put("error", t.getMessage());
                                result.error("ERROR", t.getMessage(), details);
                            } catch (Throwable x) {
                                result.error("ERROR", t.getMessage(), null);
                            }
                        } else {
                            Log.w(TAG, "Paged sync onFailure ignored: reply already sent");
                        }
                    }
                });
            }

            @Override
            public void onFailure(Throwable t) {
                Log.e(TAG, "Failed to get record num (paged)", t);
                    if (replied.compareAndSet(false, true)) {
                        try {
                            Map<String, Object> details = new HashMap<>();
                            details.put("error", t.getMessage());
                            result.error("ERROR", t.getMessage(), details);
                        } catch (Throwable x) {
                            result.error("ERROR", t.getMessage(), null);
                        }
                    } else {
                        Log.w(TAG, "Paged getRecordNum onFailure ignored: reply already sent");
                    }
            }
        });
    }

    private void recursiveQueryRecords() {
        Log.d(TAG, "Querying records from index: " + currentSyncIndex);
        SyncLockRecordAction action = new SyncLockRecordAction(currentSyncIndex, 10, syncLogVersion);
        action.setBaseAuthAction(syncAuth);

        bleClient.syncLockRecord(action, new FunCallback<LockRecordDataResult>() {
            @Override
             public void onResponse(Response<LockRecordDataResult> response) {
                 if (response.isSuccessful() && response.body() != null) {
                     LockRecordDataResult body = response.body();
                     Log.d(TAG, "Got batch of " + body.getLogNum() + " records");

                     // Process logs
                     if (body.getLogNum() > 0) {
                          if (syncLogVersion == 1) {
                              for (HXRecordBaseModel r : body.getLog1Array()) {
                                  Map<String, Object> m = mapRecord(r);
                                  m.put("logVersion", 1);
                                  syncLogList.add(m);
                              }
                          } else if (syncLogVersion == 2) {
                              for (HXRecord2BaseModel r : body.getLog2Array()) {
                                  Map<String, Object> m = mapRecord(r);
                                  m.put("logVersion", 2);
                                  syncLogList.add(m);
                              }
                          }
                          currentSyncIndex += body.getLogNum();
                     }

                     // Recursion or finish
                     if (!body.isMoreData() || currentSyncIndex >= totalSyncRecords) {
                         Log.d(TAG, "Sync complete, returning " + syncLogList.size() + " records");
                         if (syncReplied.compareAndSet(false, true)) {
                            syncResult.success(syncLogList);
                         } else {
                            Log.w(TAG, "Sync complete ignored: reply already sent");
                         }
                     } else {
                         recursiveQueryRecords();
                     }
                 } else {
                      Log.e(TAG, "Sync failed at index " + currentSyncIndex + " code: " + response.code());
                      if (syncReplied.compareAndSet(false, true)) {
                          try {
                                    Map<String, Object> details = new HashMap<>();
                                    details.put("code", response.code());
                                    details.put("ackMessage", WiseStatusCode.description(response.code()));
                              syncResult.error("FAILED", "Sync Failed: " + response.code(), details);
                          } catch (Throwable t) {
                              syncResult.error("FAILED", "Sync Failed: " + response.code(), null);
                          }
                      } else {
                          Log.w(TAG, "Sync failed ignored: reply already sent");
                      }
                 }
             }
             @Override
             public void onFailure(Throwable t) {
                 Log.e(TAG, "Sync failed exception", t);
                 if (syncReplied.compareAndSet(false, true)) {
                     try {
                         Map<String, Object> details = new HashMap<>();
                         details.put("error", t.getMessage());
                         syncResult.error("ERROR", t.getMessage(), details);
                     } catch (Throwable x) {
                         syncResult.error("ERROR", t.getMessage(), null);
                     }
                 } else {
                     Log.w(TAG, "Sync onFailure ignored: reply already sent");
                 }
             }
        });
    }

    /**
     * Convert an HXRecord* instance into a flat Map<String, Object>.
     *
     * <p>This uses reflection so that we don't depend on a particular
     * generated model version from the HXJ BLE SDK. All non-static
     * fields from the concrete class and its superclasses are
     * exported using their field names as keys. Primitive wrapper
     * types, String, Number and Boolean are passed through as-is;
     * other types fall back to their toString() representation.</p>
     */
    private Map<String, Object> mapRecord(Object record) {
        Map<String, Object> out = new HashMap<>();
        if (record == null) {
            return out;
        }

        Class<?> clazz = record.getClass();
        // Help the Dart side distinguish between variants.
        out.put("modelType", clazz.getSimpleName());

        while (clazz != null && clazz != Object.class) {
            Field[] fields = clazz.getDeclaredFields();
            for (Field field : fields) {
                if (Modifier.isStatic(field.getModifiers())) {
                    continue;
                }
                field.setAccessible(true);
                try {
                    Object value = field.get(record);
                    if (value == null) {
                        continue;
                    }

                    if (value instanceof Number ||
                            value instanceof Boolean ||
                            value instanceof String) {
                        out.put(field.getName(), value);
                    } else {
                        // enums or complex objects: use string form
                        out.put(field.getName(), value.toString());
                    }
                } catch (IllegalAccessException e) {
                    Log.w(TAG, "Unable to read field " + field.getName() +
                            " from " + clazz.getSimpleName(), e);
                }
            }
            clazz = clazz.getSuperclass();
        }

        return out;
    }
}
