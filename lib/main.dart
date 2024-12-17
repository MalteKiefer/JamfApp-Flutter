import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/settings.dart';
import 'screens/devicedetail.dart';
import 'screens/computerdetail.dart';
import 'package:intl/intl.dart';
import 'helper/func.dart';

void main() => runApp(JamfProApp());

class JamfProApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: LoginScreen(),
    );
  }
}

class LoginScreen extends StatefulWidget {
  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  String? authToken;

  @override
  void initState() {
    super.initState();
    _loadLoginData();
  }

  Future<void> _loadLoginData() async {
    final prefs = await SharedPreferences.getInstance();
    final savedUrl = prefs.getString('url') ?? '';
    final savedUsername = prefs.getString('username') ?? '';
    final savedPassword = prefs.getString('password') ?? '';

    _urlController.text = savedUrl;
    _usernameController.text = savedUsername;
    _passwordController.text = savedPassword;
  }

  void _login() async {
    final url = _urlController.text;
    final username = _usernameController.text;
    final password = _passwordController.text;

    if (url.isEmpty || username.isEmpty || password.isEmpty) {
      _showError('Please fill in all fields.');
      return;
    }

    try {
      // Save login data
      final prefs = await SharedPreferences.getInstance();
      prefs.setString('url', url);
      prefs.setString('username', username);
      prefs.setString('password', password);

      // Generate token
      final tokenResponse = await http.post(
        Uri.parse('$url/api/v1/auth/token'),
        headers: {
          'Authorization':
              'Basic ' + base64Encode(utf8.encode('$username:$password')),
          'Accept': 'application/json',
        },
      );

      if (tokenResponse.statusCode == 200) {
        final tokenData = json.decode(tokenResponse.body);
        authToken = tokenData['token'];
        prefs.setString('authToken', authToken.toString());

        // Fetch mobile devices
        final mobileResponse = await http.get(
          Uri.parse('$url/JSSResource/mobiledevices'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        );

        // Fetch computers
        final computerResponse = await http.get(
          Uri.parse('$url/JSSResource/computers/subset/basic'),
          headers: {
            'Authorization': 'Bearer $authToken',
            'Accept': 'application/json',
          },
        );

        if (mobileResponse.statusCode == 200 &&
            computerResponse.statusCode == 200) {
          final mobileData = json.decode(mobileResponse.body);
          final devices = (mobileData['mobile_devices'] as List).toList()
            ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));

          final computerData = json.decode(computerResponse.body);
          final computers = (computerData['computers'] as List).toList()
            ..sort((a, b) => (a['name'] ?? '').compareTo(b['name'] ?? ''));
          print(devices);

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  HomeScreen(devices: devices, computers: computers),
            ),
          );
        } else {
          _showError('Failed to fetch devices or computers');
        }
      } else {
        _showError(
            'Token generation failed: ${tokenResponse.statusCode} ${tokenResponse.reasonPhrase}');
      }
    } catch (e) {
      _showError('An error occurred: $e');
    }
  }

  void _showError(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        // Zentriert die Inhalte horizontal und vertikal
        child: SingleChildScrollView(
          // Scrollbar bei kleineren Bildschirmen
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min, // Minimale Größe der Column
              children: [
                // Logo
                Image.asset(
                  'assets/logo.png', // Ersetze durch deinen Pfad zum Logo
                  height: 100,
                  width: 100,
                ),
                SizedBox(height: 30),

                // URL Eingabefeld
                TextField(
                  controller: _urlController,
                  decoration: InputDecoration(
                    labelText: 'Jamf Pro URL',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Username Eingabefeld
                TextField(
                  controller: _usernameController,
                  decoration: InputDecoration(
                    labelText: 'Username',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 20),

                // Passwort Eingabefeld
                TextField(
                  controller: _passwordController,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                ),
                SizedBox(height: 30),

                // Login Button
                ElevatedButton(
                  onPressed: _login,
                  child: Text('Login'),
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.symmetric(horizontal: 50, vertical: 15),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class DeviceListScreen extends StatefulWidget {
  final List devices;
  final bool isMobile;

  DeviceListScreen({required this.devices, required this.isMobile});

  @override
  _DeviceListScreenState createState() => _DeviceListScreenState();
}

class _DeviceListScreenState extends State<DeviceListScreen> {
  String searchQuery = '';
  bool showOfflineComputers = false;
  int offlineDuration = 30; // Default value

  // Gemeinsame Methode für API-Aufrufe
  Future<Map<String, dynamic>?> _fetchDeviceDetails(
      String deviceId, bool isMobile) async {
    final prefs = await SharedPreferences.getInstance();
    final url = prefs.getString('url') ?? '';
    final authToken = await getValidToken();
    final endpoint = isMobile
        ? '$url/JSSResource/mobiledevices/id/$deviceId'
        : '$url/JSSResource/computers/id/$deviceId';

    try {
      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Accept': 'application/json',
        },
      );
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to fetch details')),
        );
      }
    } catch (e) {
      print('Error fetching details: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error occurred: $e')),
      );
    }
    return null;
  }

  // Entscheidet, welche Details geladen und View verwendet wird
  void _showDeviceDetails(String deviceId) async {
    final deviceDetails = await _fetchDeviceDetails(deviceId, widget.isMobile);

    if (deviceDetails != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => widget.isMobile
              ? DeviceDetailScreen(deviceDetails: deviceDetails)
              : ComputerDetailScreen(deviceDetails: deviceDetails),
        ),
      );
    }
  }

  @override
  void initState() {
    super.initState();
    _loadOfflineDuration();
  }

  // Async method to load offline duration
  Future<void> _loadOfflineDuration() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      offlineDuration = prefs.getInt('offline_duration') ?? 30;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filteredDevices = widget.devices.where((device) {
      final name = device['name']?.toLowerCase() ?? '';
      final username =
          device['username']?.toLowerCase() ?? ''; // Benutzername hinzufügen
      final isComputer = !widget.isMobile;
      bool offlineSystem = false;

      // Wenn es ein Computer ist, prüfe, ob er offline ist
      if (isComputer) {
        final reportDateUtcRaw = device['report_date_utc'];
        final reportDateUtc = DateTime.tryParse(reportDateUtcRaw ?? '');
        if (reportDateUtc != null) {
          final nowUtc = DateTime.now().toUtc();
          final diffInMinutes = nowUtc.difference(reportDateUtc).inMinutes;
          offlineSystem =
              diffInMinutes > offlineDuration; // offline mehr als 30 Minuten
        }
      }

      // Filter basierend auf Suchanfrage, Name, Username und Offline-Status
      final matchesSearch = name.contains(searchQuery.toLowerCase()) ||
          username.contains(searchQuery.toLowerCase());

      return matchesSearch &&
          (!isComputer || !offlineSystem || showOfflineComputers);
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isMobile ? 'Mobile Devices' : 'Computers'),
        actions: widget.isMobile
            ? []
            : [
                // Add a filter button for toggling the offline filter
                IconButton(
                  icon: Icon(showOfflineComputers
                      ? Icons.visibility_off
                      : Icons.visibility),
                  onPressed: () {
                    setState(() {
                      showOfflineComputers = !showOfflineComputers;
                    });
                  },
                ),
              ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                labelText: 'Search',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: ListView.separated(
              itemCount: filteredDevices.length,
              itemBuilder: (context, index) {
                final device = filteredDevices[index];
                final isSupervised =
                    (device['supervised'] == true || device['managed'] == true);
                final username = device['username'];
                final lastcheckindate = device['report_date_utc'];
                bool offline = false;

                if (!widget.isMobile) {
                  final reportDateUtcRaw = device['report_date_utc'];
                  final reportDateUtc = DateTime.parse(reportDateUtcRaw ?? '');
                  final nowUtc = DateTime.now().toUtc();
                  final diffInMinutes =
                      nowUtc.difference(reportDateUtc).inMinutes;
                  offline = diffInMinutes >
                      offlineDuration; // Mark as offline if more than 30 minutes
                }

                return ListTile(
                  leading: Icon(
                    widget.isMobile
                        ? Icons
                            .phone_android // Immer Handy-Icon für mobile Geräte
                        : Icons.computer, // Computer-Icon für Computer
                    color: widget.isMobile
                        ? Colors.lightGreen // Immer grün für mobile Geräte
                        : (offline
                            ? Colors.blueGrey
                            : Colors.lightGreen), // Grau oder grün für Computer
                  ),
                  title: Text(device['name'] ?? 'Unknown Device'),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (!widget.isMobile)
                        Text('Last Checkin: ' +
                            DateFormat('HH:mm, dd.MM.yyyy').format(
                                DateTime.parse(lastcheckindate).toLocal())),
                      if (username != null && username.isNotEmpty)
                        Text(username,
                            style: TextStyle(
                                color: Colors.black,
                                fontWeight: FontWeight.w400))
                      else
                        Text('-',
                            style: TextStyle(
                                color:
                                    const Color.fromARGB(255, 153, 148, 148))),
                      Text('Model: ${device['model']}'),
                      if (isSupervised)
                        Text('COBO',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 66, 143, 43)))
                      else
                        Text('BYOD',
                            style: TextStyle(
                                color: const Color.fromARGB(255, 236, 99, 99))),
                    ],
                  ),
                  onTap: () => _showDeviceDetails(device['id'].toString()),
                );
              },
              separatorBuilder: (context, index) => Divider(),
            ),
          ),
        ],
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  final List devices;
  final List computers;

  HomeScreen({required this.devices, required this.computers});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Devices and Computers')),
      drawer: Drawer(
        child: Column(
          children: [
            // Wallpaper at the top of the Drawer
            Container(
              height: 150,
              width: double.infinity,
              decoration: BoxDecoration(
                image: DecorationImage(
                  image: AssetImage(
                      'assets/drawer_wallpaper.jpg'), // Replace with your asset path
                  fit: BoxFit.cover,
                ),
              ),
            ),
            Expanded(
              child: ListView(
                children: [
                  ListTile(
                    leading: Icon(Icons.computer),
                    title: Text('Computers'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceListScreen(
                              devices: computers, isMobile: false),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.phone_android),
                    title: Text('Mobile Devices'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => DeviceListScreen(
                              devices: devices, isMobile: true),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.dns),
                    title: Text('Server'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => ServerScreen()),
                      );
                    },
                  ),
                  ListTile(
                    leading: Icon(Icons.update),
                    title: Text('Software-Updates'),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => UpdatesScreen()),
                      );
                    },
                  ),
                ],
              ),
            ),
            // Logout and Settings at the bottom
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(Icons.logout),
                    onPressed: () {
                      Navigator.pushReplacement(
                        context,
                        MaterialPageRoute(
                          builder: (context) => LoginScreen(),
                        ),
                      );
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.settings),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => SettingsScreen(),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Computers Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DeviceListScreen(devices: computers, isMobile: false),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.computer, size: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Computers',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${computers.length}',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            SizedBox(height: 16),
            // Mobile Devices Card
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        DeviceListScreen(devices: devices, isMobile: true),
                  ),
                );
              },
              child: Card(
                elevation: 5,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Icon(Icons.phone_android, size: 40),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'Mobile Devices',
                            style: TextStyle(fontSize: 18),
                          ),
                          SizedBox(height: 5),
                          Text(
                            '${devices.length}',
                            style: TextStyle(
                                fontSize: 30, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class UpdatesScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> updates = [
      'Update 1: New features added.',
      'Update 2: Bug fixes applied.',
      'Update 3: System performance improved.',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Updates'),
      ),
      body: ListView.builder(
        itemCount: updates.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.update),
            title: Text(updates[index]),
          );
        },
      ),
    );
  }
}

class ServerScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    List<String> servers = [
      'Server 1: Online',
      'Server 2: Offline',
      'Server 3: Maintenance',
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Server'),
      ),
      body: ListView.builder(
        itemCount: servers.length,
        itemBuilder: (context, index) {
          return ListTile(
            leading: Icon(Icons.computer),
            title: Text(servers[index]),
          );
        },
      ),
    );
  }
}
