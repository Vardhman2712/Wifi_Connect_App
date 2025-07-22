import 'dart:io';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';
import '../utils/wifi_utils.dart';
import '../models/wifi_model.dart';

class WifiScannerScreen extends StatefulWidget {
  const WifiScannerScreen({super.key});

  @override
  State<WifiScannerScreen> createState() => _WifiScannerScreenState();
}

class _WifiScannerScreenState extends State<WifiScannerScreen> {
  List<WifiNetworkModel> dbNetworks = [];
  List<String> scannedSSIDs = [];
  bool isLoading = true;
  String statusMessage = "Initializing...";

  @override
  void initState() {
    super.initState();
    _initializeScanner();
  }

  Future<void> _initializeScanner() async {
    setState(() {
      isLoading = true;
      statusMessage = "Initializing...";
    });
    try {
      // Load database
      List<WifiNetworkModel> dbList = [];
      try {
        dbList = await loadWifiDatabase();
      } catch (e) {
        setState(() {
          isLoading = false;
          statusMessage = "Failed to load WiFi database: $e";
        });
        return;
      }
      // Scan for nearby networks
      List<String> scanned = [];
      if (Platform.isAndroid) {
        try {
          final can = await WiFiScan.instance.canStartScan();
          if (can == CanStartScan.yes) {
            await WiFiScan.instance.startScan();
            await Future.delayed(Duration(seconds: 2));
            final results = await WiFiScan.instance.getScannedResults();
            scanned = results
                .map((e) => e.ssid)
                .where((ssid) => ssid.isNotEmpty)
                .toSet()
                .toList();
          }
        } catch (e) {
          // Ignore scan errors for demo
        }
      }
      setState(() {
        dbNetworks = dbList;
        scannedSSIDs = scanned;
        isLoading = false;
        statusMessage = (dbList.isEmpty && scanned.isEmpty)
            ? "No WiFi networks found."
            : "";
      });
    } catch (e) {
      setState(() {
        isLoading = false;
        statusMessage = "Unexpected error: $e";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text("Available WiFi Networks")),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : (dbNetworks.isEmpty && scannedSSIDs.isEmpty)
          ? Center(child: Text(statusMessage))
          : ListView(
              children: [
                if (scannedSSIDs.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Nearby Networks (Scanned)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...scannedSSIDs.map(
                    (ssid) => ListTile(
                      title: Text(ssid),
                      subtitle: Text("Scanned network"),
                    ),
                  ),
                ],
                if (dbNetworks.isNotEmpty) ...[
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      "Sample Networks (Database)",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  ...dbNetworks.map(
                    (wifi) => ListTile(
                      title: Text(wifi.ssid),
                      subtitle: Text("Tap to connect (Sample)"),
                      onTap: () async {
                        final decodedPassword = decodePassword(
                          wifi.passwordEncrypted,
                        );
                        showDialog(
                          context: context,
                          builder: (_) => AlertDialog(
                            title: Text("WiFi Info"),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text("SSID: ${wifi.ssid}"),
                                Text("Password: $decodedPassword"),
                              ],
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: Text("OK"),
                              ),
                              if (Platform.isAndroid) ...[
                                TextButton(
                                  onPressed: () async {
                                    await WiFiForIoTPlugin.connect(
                                      wifi.ssid,
                                      password: decodedPassword,
                                      security: NetworkSecurity.WPA,
                                    );
                                    Navigator.pop(context);
                                  },
                                  child: Text("Connect"),
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ],
            ),
    );
  }
}
