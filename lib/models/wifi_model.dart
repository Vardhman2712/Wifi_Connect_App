class WifiNetworkModel {
  final String ssid;
  final String passwordEncrypted;
  final double latitude;
  final double longitude;

  WifiNetworkModel({
    required this.ssid,
    required this.passwordEncrypted,
    required this.latitude,
    required this.longitude,
  });

  factory WifiNetworkModel.fromJson(Map<String, dynamic> json) {
    return WifiNetworkModel(
      ssid: json['ssid'],
      passwordEncrypted: json['password_encrypted'],
      latitude: json['location']['latitude'].toDouble(),
      longitude: json['location']['longitude'].toDouble(),
    );
  }
}
