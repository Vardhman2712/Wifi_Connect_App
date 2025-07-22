import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:wifi_scan/wifi_scan.dart';
import 'package:wifi_iot/wifi_iot.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

Future<void> _addNetworkDialog() async {
  final formKey = GlobalKey<FormState>();
  String networkName = '';
  String ssid = '';
  String password = '';

  final dialogContext = context;
  await showDialog(
    context: dialogContext,
    builder: (alertDialogContext) => AlertDialog(
      title: Text('Add New Network'),
      content: Form(
        key: formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextFormField(
              decoration: InputDecoration(labelText: 'Network Name'),
              onChanged: (v) => networkName = v.trim(),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'SSID'),
              onChanged: (v) => ssid = v.trim(),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
            ),
            TextFormField(
              decoration: InputDecoration(labelText: 'Password'),
              onChanged: (v) => password = v.trim(),
              validator: (v) => v == null || v.trim().isEmpty ? 'Required' : null,
              obscureText: true,
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(alertDialogContext),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () async {
            if (formKey.currentState!.validate()) {
              final prefs = await SharedPreferences.getInstance();
              final userNetworks = prefs.getStringList('user_networks') ?? [];

              final newNetwork = {
                'ssid': ssid,
                'password_encrypted': base64.encode(utf8.encode(password)),
                'location': {'latitude': 0.0, 'longitude': 0.0},
                'network_name': networkName,
              };

              userNetworks.add(json.encode(newNetwork));
              await prefs.setStringList('user_networks', userNetworks);

              if (mounted) Navigator.pop(alertDialogContext);
              await _initializeScanner(); // Refresh after saving
            }
          },
          child: Text('Save'),
        ),
      ],
    ),
  );
}

Future<void> _initializeScanner() async {
  setState(() {
    isLoading = true;
    statusMessage = "Initializing...";
  });
  try {
    // Load database (asset + user-added)
    List<WifiNetworkModel> dbList = [];
    try {
      dbList = await loadWifiDatabase();
      final prefs = await SharedPreferences.getInstance();
      final userNetworks = prefs.getStringList('user_networks') ?? [];
      dbList.addAll(
        userNetworks.map((e) => WifiNetworkModel.fromJson(json.decode(e))),
      );
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
      appBar: AppBar(
        title: Text("Available WiFi Networks"),
        centerTitle: true,
        backgroundColor: Colors.blue,
        actions: [
          IconButton(
            icon: Icon(Icons.add),
            tooltip: 'Add Network',
            onPressed: _addNetworkDialog,
          ),
        ],
      ),
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
                              if (Platform.isAndroid)
                                TextButton(
                                  onPressed: () async {
                                    await WiFiForIoTPlugin.connect(
                                      wifi.ssid,
                                      password: decodedPassword,
                                      security: NetworkSecurity.WPA,
                                    );
                                    if (context.mounted) Navigator.pop(context);
                                  },
                                  child: Text("Connect"),
                                ),
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
