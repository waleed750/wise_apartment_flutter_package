/// WiFi registration event from the lock device.
///
/// This model represents real-time status updates during WiFi configuration.
/// Events are emitted through [WiseApartment.wifiRegistrationStream].
class WifiRegistrationEvent {
  /// Raw status code from the device
  final int status;

  /// Human-readable status message
  final String statusMessage;

  /// MAC address of the RF/WiFi module
  final String moduleMac;

  /// MAC address of the lock device
  final String lockMac;

  /// Timestamp when the event was received
  final DateTime timestamp;

  const WifiRegistrationEvent({
    required this.status,
    required this.statusMessage,
    required this.moduleMac,
    required this.lockMac,
    required this.timestamp,
  });

  /// Creates a [WifiRegistrationEvent] from a Map received from native platform
  factory WifiRegistrationEvent.fromMap(Map<String, dynamic> map) {
    return WifiRegistrationEvent(
      status: (map['status'] as num?)?.toInt() ?? 0,
      statusMessage: map['statusMessage'] as String? ?? 'Unknown status',
      moduleMac: map['moduleMac'] as String? ?? '',
      lockMac: map['lockMac'] as String? ?? '',
      timestamp: DateTime.now(),
    );
  }

  /// Converts this event to a Map
  Map<String, dynamic> toMap() {
    return {
      'status': status,
      'statusMessage': statusMessage,
      'moduleMac': moduleMac,
      'lockMac': lockMac,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  /// Status code constants
  static const int statusBindingInProgress = 0x02;
  static const int statusRouterConnected = 0x04;
  static const int statusCloudConnected = 0x05;
  static const int statusIncorrectPassword = 0x06;
  static const int statusTimeout = 0x07;
  static const int statusServerConnectionFailed = 0x08;
  static const int statusDeviceNotAuthorized = 0x09;

  /// Returns true if this is a success status (0x05)
  bool get isSuccess => status == statusCloudConnected;

  /// Returns true if this is an error status (0x06, 0x07, 0x08, 0x09)
  bool get isError =>
      status == statusIncorrectPassword ||
      status == statusTimeout ||
      status == statusServerConnectionFailed ||
      status == statusDeviceNotAuthorized;

  /// Returns true if this is a progress status (0x02, 0x04)
  bool get isProgress =>
      status == statusBindingInProgress || status == statusRouterConnected;

  /// Returns true if this is a terminal state (success or error)
  bool get isTerminal => isSuccess || isError;

  /// Returns the status code as a hex string (e.g., "0x05")
  String get statusHex => '0x${status.toRadixString(16).padLeft(2, '0')}';

  /// Returns a friendly name for the status
  String get statusName {
    switch (status) {
      case statusBindingInProgress:
        return 'Binding in Progress';
      case statusRouterConnected:
        return 'Router Connected';
      case statusCloudConnected:
        return 'Cloud Connected (Success)';
      case statusIncorrectPassword:
        return 'Incorrect Password';
      case statusTimeout:
        return 'Configuration Timeout';
      case statusServerConnectionFailed:
        return 'Server Connection Failed';
      case statusDeviceNotAuthorized:
        return 'Device Not Authorized';
      default:
        return 'Unknown Status ($statusHex)';
    }
  }

  /// Returns a short emoji representation of the status
  String get statusEmoji {
    if (isSuccess) return '✅';
    if (isError) return '❌';
    if (isProgress) return '⏳';
    return '❓';
  }

  /// Returns a color-appropriate description based on status type
  /// Useful for UI color selection
  String get statusType {
    if (isSuccess) return 'success';
    if (isError) return 'error';
    if (isProgress) return 'progress';
    return 'unknown';
  }

  @override
  String toString() {
    return 'WifiRegistrationEvent('
        'status: $statusHex, '
        'message: $statusMessage, '
        'moduleMac: $moduleMac, '
        'lockMac: $lockMac, '
        'timestamp: $timestamp'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is WifiRegistrationEvent &&
        other.status == status &&
        other.statusMessage == statusMessage &&
        other.moduleMac == moduleMac &&
        other.lockMac == lockMac;
  }

  @override
  int get hashCode {
    return status.hashCode ^
        statusMessage.hashCode ^
        moduleMac.hashCode ^
        lockMac.hashCode;
  }

  /// Creates a copy of this event with the given fields replaced
  WifiRegistrationEvent copyWith({
    int? status,
    String? statusMessage,
    String? moduleMac,
    String? lockMac,
    DateTime? timestamp,
  }) {
    return WifiRegistrationEvent(
      status: status ?? this.status,
      statusMessage: statusMessage ?? this.statusMessage,
      moduleMac: moduleMac ?? this.moduleMac,
      lockMac: lockMac ?? this.lockMac,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
