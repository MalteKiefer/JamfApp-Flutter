import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Für die Datumsauswahl

class UpdatesScreen extends StatefulWidget {
  final List<dynamic> computerGroups; // Gruppen werden übergeben

  UpdatesScreen({required this.computerGroups});

  @override
  _UpdatesScreenState createState() => _UpdatesScreenState();
}

class _UpdatesScreenState extends State<UpdatesScreen> {
  late List<dynamic> _computerGroups;
  dynamic _selectedGroup;
  String? _selectedVersionType; // Ausgewählter Versionstyp
  String? _selectedSpecificVersion; // Ausgewählte spezifische Version
  String? _selectedActionType; // Ausgewählter Aktionstyp
  TextEditingController _intInputController = TextEditingController();
  TextEditingController _dateInputController = TextEditingController();

  // Liste der spezifischen Versionen
  final List<String> specificVersions = [
    "15.2",
    "15.1.1",
    "15.1",
    "15.0.1",
    "15.0",
    "14.7.2",
    "14.7.1",
    "14.7",
    "13.7.2",
    "13.7.1",
    "13.7",
    "12.7.6",
    "11.7.10"
  ];

  // Liste der Versionstypen
  final List<Map<String, String>> versionTypes = [
    {
      "text": "Latest version based on device eligibility",
      "value": "LATEST_ANY"
    },
    {"text": "Latest major version", "value": "LATEST_MAJOR"},
    {"text": "Latest minor version", "value": "LATEST_MINOR"},
    {"text": "Specific version", "value": "SPECIFIC_VERSION"},
  ];

  final List<Map<String, String>> actionTypes = [
    {"text": "Download only", "value": "DOWNLOAD_ONLY"},
    {"text": "Download and install", "value": "DOWNLOAD_INSTALL"},
    {
      "text": "Download and schedule to install",
      "value": "DOWNLOAD_INSTALL_ALLOW_DEFERRAL"
    },
    {
      "text": "Download, install, and allow deferral",
      "value": "DOWNLOAD_INSTALL_SCHEDULE"
    },
    {
      "text": "Download, install, and restart",
      "value": "DOWNLOAD_INSTALL_RESTART"
    },
  ];

  @override
  void initState() {
    super.initState();
    _computerGroups =
        widget.computerGroups; // Übergebene Gruppen initialisieren
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Software Updates'),
        actions: [],
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
                    if (_computerGroups.isEmpty)
                      Center(
                          child: Text(
                              'No groups available')) // Hinweis, wenn keine Gruppen vorhanden sind
                    else
                      DropdownButton<dynamic>(
                        isExpanded: true,
                        value: _selectedGroup,
                        hint: Text('Select a group'),
                        items: _computerGroups.map((group) {
                          return DropdownMenuItem(
                            value: group,
                            child: Text(group['name']), // Name anzeigen
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedGroup = value;
                          });
                          print('Selected ID: ${value['id']}'); // ID ausgeben
                        },
                      ),
                    DropdownButton<dynamic>(
                      isExpanded: true,
                      value: _selectedActionType,
                      hint: Text('Select update action'),
                      items: actionTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['text']!), // Text anzeigen
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedActionType = value;
                        });
                        print('Selected Action Type: $value');
                      },
                    ),
                    DropdownButton<dynamic>(
                      isExpanded: true,
                      value: _selectedVersionType,
                      hint: Text('Select version type'),
                      items: versionTypes.map((type) {
                        return DropdownMenuItem(
                          value: type['value'],
                          child: Text(type['text']!), // Text anzeigen
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _selectedVersionType = value;
                          if (value != "SPECIFIC_VERSION") {
                            _selectedSpecificVersion = null;
                          }
                        });
                        print('Selected Version Type: $value');
                      },
                    ),
                    if (_selectedVersionType == "SPECIFIC_VERSION") ...[
                      SizedBox(height: 20),
                      DropdownButton<dynamic>(
                        isExpanded: true,
                        value: _selectedSpecificVersion,
                        hint: Text('Select version'),
                        items: specificVersions.map((version) {
                          return DropdownMenuItem(
                            value: version,
                            child: Text(version), // Version anzeigen
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedSpecificVersion = value;
                          });
                          print('Selected Specific Version: $value');
                        },
                      ),
                    ],
                    if (_selectedActionType ==
                        "DOWNLOAD_INSTALL_ALLOW_DEFERRAL") ...[
                      SizedBox(height: 20),
                      TextField(
                        controller: _intInputController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Deferral',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                      ),
                    ],
                    if (_selectedActionType == "DOWNLOAD_INSTALL_SCHEDULE") ...[
                      SizedBox(height: 20),
                      TextField(
                        controller: _dateInputController,
                        readOnly: true,
                        decoration: InputDecoration(
                          labelText: 'Choose install date',
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                              horizontal: 16, vertical: 12),
                        ),
                        onTap: () async {
                          DateTime? pickedDate = await showDatePicker(
                            context: context,
                            initialDate: DateTime.now(),
                            firstDate: DateTime(2000),
                            lastDate: DateTime(2101),
                          );
                          if (pickedDate != null) {
                            setState(() {
                              _dateInputController.text =
                                  DateFormat('yyyy-MM-dd').format(pickedDate);
                            });
                          }
                        },
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
