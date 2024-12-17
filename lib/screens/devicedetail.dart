import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/func.dart';

class DeviceDetailScreen extends StatelessWidget {
  final Map deviceDetails;

  DeviceDetailScreen({required this.deviceDetails});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> applicationItems = {};
    for (final app in deviceDetails['mobile_device']['applications']) {
      final appName = app['application_name'] ?? 'Unknown App';
      final appInfo = 'Version: ${app['application_short_version'] ?? 'N/A'}\n'
          'Identifier: ${app['identifier'] ?? 'N/A'}';
      applicationItems[appName] = appInfo;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(deviceDetails['mobile_device']['general']['name'] ??
            'Device Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Section(
              title: 'Device',
              items: {
                'ID': deviceDetails['mobile_device']['general']['id']
                        .toString() ??
                    'N/A',
                'Model':
                    deviceDetails['mobile_device']['general']['model'] ?? 'N/A',
                'Seriennummer': deviceDetails['mobile_device']['general']
                        ['serial_number'] ??
                    'N/A',
                'UDID':
                    deviceDetails['mobile_device']['general']['udid'] ?? 'N/A',
                'Model Identifier': deviceDetails['mobile_device']['general']
                        ['model_identifier'] ??
                    'N/A',
              },
            ),
            Section(
              title: 'Network',
              items: {
                'IP': deviceDetails['mobile_device']['general']['ip_address'] ??
                    'N/A',
                'Wifi Mac': deviceDetails['mobile_device']['general']
                        ['wifi_mac_address'] ??
                    'N/A',
                'Bluetooth Mac': deviceDetails['mobile_device']['general']
                        ['bluetooth_mac_address'] ??
                    'N/A',
              },
            ),
            Section(
              title: 'OS',
              items: {
                'OS Type': deviceDetails['mobile_device']['general']
                        ['os_type'] ??
                    'N/A',
                'OS Version': deviceDetails['mobile_device']['general']
                        ['os_version'] ??
                    'N/A',
                'OS Build': deviceDetails['mobile_device']['general']
                        ['os_build'] ??
                    'N/A',
              },
            ),
            Section(
              title: 'Security',
              items: {
                'Supervised?': (deviceDetails['mobile_device']['general']
                            ['supervised'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Data Protection?': (deviceDetails['mobile_device']['security']
                            ['data_protection'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Passcode Present?': (deviceDetails['mobile_device']['security']
                            ['passcode_present'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Passcode Compliant?': (deviceDetails['mobile_device']
                            ['security']['passcode_compliant'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Jailbreak Detected?': deviceDetails['mobile_device']
                        ['security']['jailbreak_detected'] ??
                    'N/A',
              },
            ),
            Section(
              title: 'Applications',
              items: applicationItems,
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue, // Button color
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                await sendMobileDeviceCommand("DeviceLock",
                    deviceDetails['mobile_device']['general']['id'].toString());
              },
              child: Text('Lock Device'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await sendMobileDeviceCommand(
                      "RestartDevice",
                      deviceDetails['mobile_device']['general']['id']
                          .toString());
                },
                child: Text('Restart Device'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await sendMobileDeviceCommand(
                      "UpdateInventory",
                      deviceDetails['mobile_device']['general']['id']
                          .toString());
                },
                child: Text('Update Inventory'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red, // Button color
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (context) {
                      return AlertDialog(
                        title: Text('Confirm Erase Device'),
                        content: Text(
                            'Are you sure you want to erase this device? This action cannot be undone.'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(false),
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(context).pop(true),
                            child: Text('Confirm'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmed == true) {
                    await sendMobileDeviceCommand(
                      "EraseDevice",
                      deviceDetails['mobile_device']['general']['id']
                          .toString(),
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Erase Device command sent.')),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                          content: Text('Erase Device command cancelled.')),
                    );
                  }
                },
                child: Text('Erase Device'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class Section extends StatelessWidget {
  final String title;
  final Map<String, String> items;

  Section({required this.title, required this.items});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 12),
            ...items.entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4.0),
                child: Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: Text(
                        entry.key,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                    Expanded(
                      flex: 3,
                      child: Text(entry.value),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
