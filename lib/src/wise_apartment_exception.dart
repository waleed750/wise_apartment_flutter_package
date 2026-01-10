class WiseApartmentException implements Exception {
  final String code;
  String? message;
  Map<String, dynamic>? details;
  WiseApartmentException(this.code, this.message, [dynamic data]) {
    if (data is Map) {
      details = data.cast<String, dynamic>();
      message = details?['ackMessage'] ?? message;
    } else {
      details = (data).cast<String, dynamic>();
    }
  }

  @override
  String toString() =>
      'WiseApartmentException($code): $message , details: $details';

  Map<String, dynamic>? toMap() {
    return {'code': code, 'message': message, 'details': details};
  }
}
