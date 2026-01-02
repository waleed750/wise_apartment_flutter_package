enum WifiConfigurationType {
  serverOnly, // 1
  wifiOnly, // 2
  wifiAndServer, // 3
}

enum IpMode {
  dhcp, // 0
  manual, // 1
}

class WifiConfig {
  final String ssid;
  final String password;

  /// "01" = Update, "02" = Not updating
  final String updateToken; // "01" or "02"

  /// tokenId invalid => '' (empty string)
  final String tokenId;

  final WifiConfigurationType configurationType;

  /// Server settings valid when configurationType is 1 or 3, else ''
  final String serverAddress; // domain/IP (domain < 20 bytes)
  final String serverPort; // string

  final IpMode ipMode;

  /// Valid only if ipMode == manual, else ''
  final String manualIp;
  final String subnetMask;
  final String routerAddress;

  WifiConfig({
    required this.ssid,
    required this.password,
    this.updateToken = "01", //01: Update; 02: Not updating
    this.tokenId =
        "9/byy8/mfaIC2RbBYeDZunXURbwcx+bkKMIPVn1kyrLA4ZXqf5ryWmtfueQos+rqcgw3IA/tiAE=",
    this.configurationType = WifiConfigurationType.wifiAndServer,
    this.serverAddress = "",
    this.serverPort = "",
    this.ipMode = IpMode.dhcp,
    this.manualIp = "",
    this.subnetMask = "",
    this.routerAddress = "",
  });

  String _configTypeCode() {
    switch (configurationType) {
      case WifiConfigurationType.serverOnly:
        return "1";
      case WifiConfigurationType.wifiOnly:
        return "2";
      case WifiConfigurationType.wifiAndServer:
        return "3";
    }
  }

  String _ipModeCode() => ipMode == IpMode.dhcp ? "0" : "1";

  /// Build rfCode EXACT format:
  /// {"04"|"Update Token"|"SSID"|"Password"|"tokenId"|"Configuration Type"|"Server Address"|"Server Port"|"Automatically Get IP"|"Manually Configure IP"|"Subnet Mask"|"Router Address"}
  String toRfCodeString() {
    final cfg = _configTypeCode();

    final needServer = cfg == "1" || cfg == "3";
    final needWifi = cfg == "2" || cfg == "3";

    final ssidVal = needWifi ? ssid : "";
    final passVal = needWifi ? password : "";

    final serverAddrVal = needServer ? serverAddress : "";
    final serverPortVal = needServer ? serverPort : "";

    final ipModeVal = _ipModeCode();
    final manualIpVal = (ipMode == IpMode.manual) ? manualIp : "";
    final subnetVal = (ipMode == IpMode.manual) ? subnetMask : "";
    final routerVal = (ipMode == IpMode.manual) ? routerAddress : "";

    // NOTE: Password does NOT support '@' per documentation
    // You can enforce validation here if needed.

    final parts = <String>[
      "04",
      updateToken, // "01" or "02"
      ssidVal,
      passVal,
      tokenId,
      cfg, // "1"|"2"|"3"
      serverAddrVal,
      serverPortVal,
      ipModeVal, // "0" DHCP | "1" manual
      manualIpVal, // IP string or ""
      subnetVal,
      routerVal,
    ];

    String esc(String s) => s.replaceAll('"', r'\"'); // minimal escaping
    return "{${parts.map((e) => '"${esc(e)}"').join("|")}}";
  }
}
