import 'dart:convert';
import 'package:flutter/services.dart' show rootBundle;

import '../models/wifi_model.dart';

Future<List<WifiNetworkModel>> loadWifiDatabase() async {
  final String jsonString = await rootBundle.loadString('assets/wifi_database.json');
  final List<dynamic> jsonList = json.decode(jsonString);

  return jsonList.map((e) => WifiNetworkModel.fromJson(e)).toList();
}

String decodePassword(String encrypted) {
  try {
    return utf8.decode(base64.decode(encrypted));
  } catch (e) {
    return "Invalid Password";
  }
}
