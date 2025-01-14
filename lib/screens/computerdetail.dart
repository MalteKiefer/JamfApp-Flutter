import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../helper/func.dart';

class ComputerDetailScreen extends StatelessWidget {
  final Map deviceDetails;

  ComputerDetailScreen({required this.deviceDetails});

  @override
  Widget build(BuildContext context) {
    final Map<String, String> applicationItems = {};
    if (deviceDetails['computer']['software']['applications'] != null &&
        deviceDetails['computer']['software']['applications'] is Iterable) {
      for (final app in deviceDetails['computer']['software']['applications']) {
        final appName = app['name'] ?? 'Unknown App';
        final appInfo = 'Version: ${app['version'] ?? 'N/A'}\n'
            'Bundle Id: ${app['bundle_id'] ?? 'N/A'}';
        applicationItems[appName] = appInfo;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(
            deviceDetails['computer']['general']['name'] ?? 'Device Details'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            Section(
              title: 'Device',
              items: {
                'ID': deviceDetails['computer']['general']['id'].toString() ??
                    'N/A',
                'Model':
                    deviceDetails['computer']['hardware']['model'] ?? 'N/A',
                'Seriennummer': deviceDetails['computer']['general']
                        ['serial_number'] ??
                    'N/A',
                'UDID': deviceDetails['computer']['general']['udid'] ?? 'N/A',
                'Model Identifier': deviceDetails['computer']['hardware']
                        ['model_identifier'] ??
                    'N/A',
              },
            ),
            Section(
              title: 'User',
              items: {
                'Username': deviceDetails['computer']['location']['username']
                        .toString() ??
                    'N/A',
                'Name': deviceDetails['computer']['location']['realname']
                        .toString() ??
                    'N/A',
                'E-Mailadress': deviceDetails['computer']['location']
                        ['email_address'] ??
                    'N/A',
              },
            ),
            Section(
              title: 'Network',
              items: {
                'IP':
                    deviceDetails['computer']['general']['ip_address'] ?? 'N/A',
                'Mac': deviceDetails['computer']['general']['mac_address'] ??
                    'N/A',
              },
            ),
            Section(
              title: 'OS',
              items: {
                'OS Type':
                    deviceDetails['computer']['hardware']['os_name'] ?? 'N/A',
                'OS Version': deviceDetails['computer']['hardware']
                        ['os_version'] ??
                    'N/A',
                'OS Build':
                    deviceDetails['computer']['hardware']['os_build'] ?? 'N/A',
              },
            ),
            Section(
              title: 'Security',
              items: {
                'Supervised?': (deviceDetails['computer']['general']
                            ['supervised'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Reovery Lock enabled?': (deviceDetails['computer']['security']
                            ['recovery_lock_enabled'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Activation lock enabled?': (deviceDetails['computer']
                            ['security']['activation_lock'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Firewall enabled?': (deviceDetails['computer']['security']
                            ['firewall_enabled'] ??
                        false)
                    ? 'Yes'
                    : 'No',
                'Gatekeeper status?': deviceDetails['computer']['hardware']
                        ['gatekeeper_status'] ??
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
                await sendDeviceCommand("BlankPush",
                    deviceDetails['computer']['general']['id'].toString());
              },
              child: Text('Send Blank Push'),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue, // Button color
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await sendDeviceCommand("EnableRemoteDesktop",
                      deviceDetails['computer']['general']['id'].toString());
                },
                child: Text('Enable Remote Desktop'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blueGrey, // Button color
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  await sendDeviceCommand("DisableRemoteDesktop",
                      deviceDetails['computer']['general']['id'].toString());
                },
                child: Text('Disable Remote Desktop'),
              ),
            ),
            Container(
              margin: const EdgeInsets.only(top: 10.0),
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color.fromARGB(255, 240, 154, 148), // Button color
                  foregroundColor: Colors.white,
                ),
                onPressed: () async {
                  String? generatedCode = await sendMobileDeviceCommand(
                      "DeviceLock",
                      deviceDetails['computer']['general']['id'].toString());

                  if (generatedCode != null) {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Device Locked'),
                          content: Text(
                              'The device has been locked. Passcode: $generatedCode'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  } else {
                    showDialog(
                      context: context,
                      builder: (BuildContext context) {
                        return AlertDialog(
                          title: Text('Error'),
                          content: Text(
                              'Failed to lock the device. Please try again.'),
                          actions: [
                            TextButton(
                              onPressed: () {
                                Navigator.of(context).pop();
                              },
                              child: Text('OK'),
                            ),
                          ],
                        );
                      },
                    );
                  }
                },
                child: Text('Lock Device'),
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
                  bool? confirmDeletion = await showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return AlertDialog(
                        title: Text('Confirm Deletion'),
                        content:
                            Text('Are you sure you want to erase this device?'),
                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(false); // Cancel
                            },
                            child: Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).pop(true); // Confirm
                            },
                            child: Text('Erase'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirmDeletion == true) {
                    String? generatedCode = await sendMobileDeviceCommand(
                      "Erase Device",
                      deviceDetails['computer']['general']['id'].toString(),
                    );

                    if (generatedCode != null) {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Device erased'),
                            content: Text(
                                'The device has been erased. PIN: $generatedCode'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    } else {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: Text('Error'),
                            content: Text(
                                'Failed to erase the device. Please try again.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          );
                        },
                      );
                    }
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
