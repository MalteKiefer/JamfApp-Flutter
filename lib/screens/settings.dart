import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _urlController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  String? _offlineDuration; // Variable, um die Auswahl des Dropdowns zu speichern

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  // Lädt die gespeicherten Einstellungen
  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    _urlController.text = prefs.getString('url') ?? '';
    _usernameController.text = prefs.getString('username') ?? '';
    _passwordController.text = prefs.getString('password') ?? '';
    
    // Setzt die gespeicherte Offline-Dauer oder den Standardwert '30 min'
    setState(() {
      final _minutes = prefs.getInt('offline_duration') ?? 30;
      _offlineDuration = _minutes.toString() + ' min';
    });
  }

  // Speichert die aktuellen Einstellungen
  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    int durationInMinutes = _offlineDuration?.split(' ')[0] != null
    ? int.parse(_offlineDuration!.split(' ')[0])
    : 0;
    prefs.setString('url', _urlController.text);
    prefs.setString('username', _usernameController.text);
    prefs.setString('password', _passwordController.text);
    prefs.setInt('offline_duration', durationInMinutes ?? 30); // Offline-Dauer speichern
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Settings saved successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Settings'),
        actions: [
          // Disk-Icon zum Speichern der Einstellungen
          IconButton(
            icon: Icon(Icons.save),
            onPressed: _saveSettings,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Card für die Einstellungen
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      'Login',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(labelText: 'Jamf Pro URL'),
                    ),
                    TextField(
                      controller: _usernameController,
                      decoration: InputDecoration(labelText: 'Username'),
                    ),
                    TextField(
                      controller: _passwordController,
                      decoration: InputDecoration(labelText: 'Password'),
                      obscureText: true,
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),

            // Card für den Dropdown-Bereich
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Others',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Computer offline after: '),
                        DropdownButton<String>(
                          value: _offlineDuration, // Zeigt den gespeicherten Wert oder den Standardwert an
                          items: <String>['5 min', '10 min', '15 min', '20 min', '30 min', '60 min']
                              .map<DropdownMenuItem<String>>((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(value),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _offlineDuration = newValue;
                            });
                            _saveSettings(); // Speichern der Auswahl
                          },
                        ),
                      ],
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
