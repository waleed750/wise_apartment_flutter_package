class HxjResponse<T> {
  final int code;
  final String? message;
  final String? ackmessage;
  final bool isSuccessful;
  final bool isError;
  final String? lockMac;
  final T? body;

  const HxjResponse({
    required this.code,
    required this.isSuccessful,
    required this.isError,
    this.message,
    this.ackmessage,
    this.lockMac,
    this.body,
  });

  factory HxjResponse.fromMap(
    Map<String, dynamic> map, {
    T Function(Object? json)? bodyParser,
  }) {
    return HxjResponse<T>(
      code: (map['code'] ?? -1) as int,
      message: map['message'] as String?,
      isSuccessful: (map['isSuccessful'] ?? false) as bool,
      isError: (map['isError'] ?? false) as bool,
      lockMac: map['lockMac'] as String?,
      ackmessage: map['ackmessage'] as String?,
      body: bodyParser != null ? bodyParser(map['body']) : (map['body'] as T?),
    );
  }

  @override
  String toString() =>
      'HxjResponse(code=$code, ok=$isSuccessful, message=$message, ackmessage=$ackmessage, lockMac=$lockMac, body=$body)';
}
