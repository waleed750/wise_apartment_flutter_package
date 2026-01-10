import 'package:wise_apartment/src/wise_apartment_exception.dart';

/// A neutral container that holds status information returned from the
/// platform or embedded in `WiseApartmentException` instances. It is
/// intentionally lightweight and serializable via `toMap()`.
class WiseStatusHandler {
  final int? code; // numeric ACK/status when available
  final String? message; // free-form message or ackMessage
  final Map<String, dynamic>? details; // original details map when present

  WiseStatusHandler({this.code, this.message, this.details});

  factory WiseStatusHandler.fromMap(Map<String, dynamic>? m) {
    if (m == null) return WiseStatusHandler();
    try {
      final dynamic c = m['code'] ?? m['status'] ?? m['ack'];
      final int? code = c == null
          ? null
          : (c is int ? c : int.tryParse(c.toString()));
      final dynamic msg = m['ackMessage'] ?? m['ackMsg'] ?? m['message'];
      final String? message = msg?.toString();
      return WiseStatusHandler(
        code: code,
        message: message,
        details: Map<String, dynamic>.from(m),
      );
    } catch (_) {
      return WiseStatusHandler(details: m);
    }
  }

  factory WiseStatusHandler.fromWiseException(WiseApartmentException e) {
    try {
      final int? code = e.code.isNotEmpty ? int.tryParse(e.code) : null;
      return WiseStatusHandler(
        code: code,
        message: e.message,
        details: e.details,
      );
    } catch (_) {
      return WiseStatusHandler(message: e.message, details: e.details);
    }
  }

  Map<String, dynamic> toMap() => {
    'code': code,
    'message': message,
    'details': details,
  };

  @override
  String toString() => 'code: $code, message: $message, details: $details';
}

/// Utility parser functions for converting platform maps or exceptions
/// into `WiseStatusHandler` objects.
class WiseStatusStore {
  static WiseStatusHandler? setFromMap(Map<String, dynamic>? m) =>
      WiseStatusHandler.fromMap(m);

  static WiseStatusHandler? setFromWiseException(WiseApartmentException e) =>
      WiseStatusHandler.fromWiseException(e);

  /// Kept for backwards compatibility in places that call `clear()`;
  /// no-op now because state is not stored globally anymore.
  static void clear() {}
}
