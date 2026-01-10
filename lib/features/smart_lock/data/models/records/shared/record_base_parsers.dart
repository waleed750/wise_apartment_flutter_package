// Shared parsing helpers used by record models
int asInt(dynamic v, [int defaultValue = 0]) {
  if (v == null) return defaultValue;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) {
    final parsed = int.tryParse(v);
    return parsed ?? defaultValue;
  }
  return defaultValue;
}

int? asIntOrNull(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

String asString(dynamic v, [String defaultValue = '']) {
  if (v == null) return defaultValue;
  if (v is String) return v;
  return v.toString();
}

bool asBool(dynamic v, [bool defaultValue = false]) {
  if (v == null) return defaultValue;
  if (v is bool) return v;
  if (v is num) return v != 0;
  if (v is String) {
    final lower = v.toLowerCase();
    if (lower == 'true' || lower == '1') return true;
    if (lower == 'false' || lower == '0') return false;
  }
  return defaultValue;
}

Map<String, dynamic> asMap(dynamic v) {
  if (v == null) return <String, dynamic>{};
  if (v is Map) return Map<String, dynamic>.from(v);
  return <String, dynamic>{};
}
