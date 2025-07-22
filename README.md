# WiFi Connect App

A Flutter app to scan nearby WiFi networks and display sample (saved) networks from a local database. Users can view SSID/password for saved networks and attempt to connect (Android only).

---

## 🛠️ IDE, Packages, and Plugins Used

- **IDE:** Visual Studio Code

- **Features:**

  - Scan Nearby WiFi Networks (Android only).
  - Match Known Networks with local encrypted database.
  - Decrypt Passwords using base64 decoding.
  - Connect to WiFi directly via Android API (user confirmation may be required).
  - Fallback for iOS: Show saved networks and open WiFi settings manually.
  - GPS-Based Matching: On iOS or if scan fails, fallback to GPS proximity.
  - Permissions Handling: Location & WiFi permissions handled gracefully.
  - Clear Status Messages: Real-time UI feedback and empty state handling.

- **Packages/Plugins:**
  - [`wifi_scan`](https://pub.dev/packages/wifi_scan): Scan for nearby WiFi networks (Android only)
  - [`wifi_iot`](https://pub.dev/packages/wifi_iot): Connect to WiFi networks (Android only)
  - [`permission_handler`](https://pub.dev/packages/permission_handler): Handle runtime permissions
  - [`geolocator`](https://pub.dev/packages/geolocator): (Optional) For location-based features
  - [`url_launcher`](https://pub.dev/packages/url_launcher): Open WiFi settings (iOS fallback)

---

## 📱 Platform Limitations

- **Android:**
  - Can scan and display nearby WiFi networks.
  - Can attempt to connect to WiFi networks (user confirmation may be required on Android 10+).
- **iOS:**
  - **Cannot scan** for nearby WiFi networks (Apple restriction).
  - **Cannot connect** to WiFi programmatically.
  - Only displays sample networks and can open WiFi settings for manual connection.

--- ⚠️ iOS functionality is implemented but untested, as I do not currently have access to a physical iOS device.

## 🔒 Permissions & Database Logic

- **Permissions:**
  - Requests location and WiFi permissions at runtime using `permission_handler`.
  - Handles permission errors gracefully with user-friendly messages.
- **Database:**
  - Loads sample networks from a local JSON file (`assets/wifi_database.json`).
  - Decrypts and displays passwords for saved networks.

---

## 🗂️ Folder Structure

lib/
├── main.dart # App entry point
├── screens/
│ └── wifi_scanner_screen.dart # Core UI + logic to scan, match, and connect
├── models/
│ └── wifi_model.dart # WifiNetworkModel definition
├── utils/
│ └── wifi_utils.dart # Load and parse local JSON database
assets/
└── wifi_database.json # Encrypted known WiFi SSIDs/passwords

---

## ⭐ Bonus Features & Notes

- **UI:**
  - Separates scanned (public) and sample (database) networks in the list.
  - Tapping a sample network shows SSID, password, and a "Connect" button (Android only).
  - Tapping a scanned network can show info or open WiFi settings.
- **Error Handling:**
  - Shows clear status messages if permissions are denied or no networks are found.
- **Cross-Platform:**
  - Gracefully disables unsupported features on iOS.

---

## 🐞 Problems Faced & Solutions

- **WiFi Scanning on iOS:**

  - **Problem:** iOS does not allow scanning for WiFi networks.
  - **Solution:** The app disables scanning features on iOS and only shows sample networks.

- **Connecting to WiFi Programmatically:**

  - **Problem:** iOS and newer Android versions restrict programmatic WiFi connections.
  - **Solution:** On Android, the app uses `wifi_iot` to attempt connections (with user confirmation if needed). On iOS, the app provides a button to open WiFi settings for manual connection.

- **Permissions Handling:**

  - **Problem:** WiFi scanning and connection require runtime permissions, which can be denied by the user.
  - **Solution:** The app checks and requests permissions at startup, and displays clear error messages if permissions are missing.

- **NDK Version Mismatch:**

  - **Problem:** Some plugins required a newer Android NDK version.
  - **Solution:** Updated the `ndkVersion` in `build.gradle.kts` to match plugin requirements.

- **UI/UX Consistency:**
  - **Problem:** Needed to clearly separate scanned and sample networks and provide a smooth user experience.
  - **Solution:** Used clear section headers and dialogs, and provided feedback for unsupported actions.
