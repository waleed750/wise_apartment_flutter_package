class DnaInfoModel {
  final String? mac;
  final dynamic protocolVer;
  final dynamic authorizedRoot;
  final dynamic dnaAes128Key;

  DnaInfoModel({
    this.mac,
    this.protocolVer,
    this.authorizedRoot,
    this.dnaAes128Key,
  });

  factory DnaInfoModel.fromMap(Map<String, dynamic>? map) {
    if (map == null) return DnaInfoModel();
    return DnaInfoModel(
      mac: map['mac'] as String?,
      protocolVer: map['protocolVer'],
      authorizedRoot: map['authorizedRoot'],
      dnaAes128Key: map['dnaAes128Key'],
    );
  }

  @override
  String toString() =>
      'DnaInfoModel(mac=$mac, protocolVer=$protocolVer, authorizedRoot=$authorizedRoot)';
}
