/// Standard response wrapper for all lock operations
/// Provides consistent error handling across platforms
class LockResponse<T> {
  final bool success;
  final int? code;
  final String? message;
  final T? data;

  const LockResponse({
    required this.success,
    this.code,
    this.message,
    this.data,
  });

  factory LockResponse.fromMap(
    Map<String, dynamic> map,
    T? Function(dynamic) dataParser,
  ) {
    return LockResponse<T>(
      success: map['success'] as bool? ?? map['isSuccessful'] as bool? ?? false,
      code: map['code'] as int?,
      message: map['message'] as String? ?? map['ackMessage'] as String?,
      data: map['data'] != null ? dataParser(map['data']) : null,
    );
  }

  factory LockResponse.success(T data, {int? code, String? message}) {
    return LockResponse<T>(
      success: true,
      code: code,
      message: message,
      data: data,
    );
  }

  factory LockResponse.failure(String message, {int? code}) {
    return LockResponse<T>(
      success: false,
      code: code,
      message: message,
      data: null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'success': success,
      if (code != null) 'code': code,
      if (message != null) 'message': message,
      if (data != null) 'data': data,
    };
  }

  @override
  String toString() =>
      'LockResponse(success: $success, code: $code, message: $message, data: $data)';
}
