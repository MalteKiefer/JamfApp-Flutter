import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Für die Datumsauswahl

class UpdatesScreen extends StatefulWidget {
  final List<dynamic> computerGroups;

  UpdatesScreen({required this.computerGroups});

  @override
  UpdatesScreenState createState() => UpdatesScreenState();
}

class UpdatesScreenState extends State<UpdatesScreen> {
  late List<dynamic> _computerGroups;
  dynamic _selectedGroup;
  String? _selectedVersionType;
  String? _selectedSpecificVersion;
  String? _selectedActionType;
  TextEditingController _intInputController = TextEditingController();
  TextEditingController _dateInputController = TextEditingController();

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
      "value": "DOWNLOAD_INSTALL_SCHEDULE"
    },
    {
      "text": "Download, install, and allow deferral",
      "value": "DOWNLOAD_INSTALL_ALLOW_DEFERRAL"
    },
    {
      "text": "Download, install, and restart",
      "value": "DOWNLOAD_INSTALL_RESTART"
    },
  ];

  int _currentStep = 0;

  @override
  void initState() {
    super.initState();
    _computerGroups = widget.computerGroups;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Software Updates'),
      ),
      body: Stepper(
        currentStep: _currentStep,
        onStepContinue: () {
          if (_currentStep < 4) {
            setState(() {
              _currentStep++;
            });
          }
        },
        onStepCancel: () {
          if (_currentStep > 0) {
            setState(() {
              _currentStep--;
            });
          }
        },
        steps: [
          Step(
            title: Text('Select Group'),
            content: DropdownButton<dynamic>(
              isExpanded: true,
              value: _selectedGroup,
              hint: Text('Select a group'),
              items: _computerGroups.map((group) {
                return DropdownMenuItem(
                  value: group,
                  child: Text(group['name']),
                );
              }).toList(),
              onChanged: (value) {
                setState(() {
                  _selectedGroup = value;
                });
              },
            ),
            isActive: _currentStep >= 0,
          ),
          Step(
            title: Text('Select Update Action'),
            content: Column(
              children: [
                DropdownButton<dynamic>(
                  isExpanded: true,
                  value: _selectedActionType,
                  hint: Text('Select update action'),
                  items: actionTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['text']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedActionType = value;
                    });
                  },
                ),
                if (_selectedActionType == "DOWNLOAD_INSTALL_ALLOW_DEFERRAL")
                  TextField(
                    controller: _intInputController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      labelText: 'Deferral',
                      border: OutlineInputBorder(),
                    ),
                  ),
                if (_selectedActionType == "DOWNLOAD_INSTALL_SCHEDULE")
                  TextField(
                    controller: _dateInputController,
                    readOnly: true,
                    decoration: InputDecoration(
                      labelText: 'Choose install date',
                      border: OutlineInputBorder(),
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
            ),
            isActive: _currentStep >= 1,
          ),
          Step(
            title: Text('Select Version Type'),
            content: Column(
              children: [
                DropdownButton<dynamic>(
                  isExpanded: true,
                  value: _selectedVersionType,
                  hint: Text('Select version type'),
                  items: versionTypes.map((type) {
                    return DropdownMenuItem(
                      value: type['value'],
                      child: Text(type['text']!),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _selectedVersionType = value;
                      if (value != "SPECIFIC_VERSION") {
                        _selectedSpecificVersion = null;
                      }
                    });
                  },
                ),
                if (_selectedVersionType == "SPECIFIC_VERSION")
                  DropdownButton<dynamic>(
                    isExpanded: true,
                    value: _selectedSpecificVersion,
                    hint: Text('Select version'),
                    items: specificVersions.map((version) {
                      return DropdownMenuItem(
                        value: version,
                        child: Text(version),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _selectedSpecificVersion = value;
                      });
                    },
                  ),
              ],
            ),
            isActive: _currentStep >= 2,
          ),
          Step(
            title: Text('Review Selection'),
            content: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'Selected Group: ${_selectedGroup != null ? _selectedGroup['name'] : 'None'}'),
                Text('Selected Action: $_selectedActionType'),
                if (_selectedActionType == "DOWNLOAD_INSTALL_ALLOW_DEFERRAL")
                  Text('Deferral: ${_intInputController.text}'),
                if (_selectedActionType == "DOWNLOAD_INSTALL_SCHEDULE")
                  Text('Install Date: ${_dateInputController.text}'),
                Text('Version Type: $_selectedVersionType'),
                if (_selectedVersionType == "SPECIFIC_VERSION")
                  Text('Specific Version: $_selectedSpecificVersion'),
              ],
            ),
            isActive: _currentStep >= 3,
          ),
        ],
      ),
    );
  }
}
