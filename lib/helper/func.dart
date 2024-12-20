import 'dart:ffi';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

Future<String?> getValidToken() async {
  final prefs = await SharedPreferences.getInstance();
  final savedToken =
      prefs.getString('authToken'); // Lade den gespeicherten Token
  final savedUrl = prefs.getString('url') ?? '';
  final savedUsername = prefs.getString('username') ?? '';
  final savedPassword = prefs.getString('password') ?? '';

  if (savedToken != null) {
    // Überprüfen, ob der Token gültig ist
    try {
      final verifyResponse = await http.get(
        Uri.parse('$savedUrl/api/v1/auth/verify-token'),
        headers: {
          'Authorization': 'Bearer $savedToken',
          'Accept': 'application/json',
        },
      );

      if (verifyResponse.statusCode == 200) {
        return savedToken; // Token ist gültig
      }
    } catch (e) {
      print('Token verification failed: $e');
    }
  }

  // Falls der Token nicht vorhanden oder ungültig ist, generiere einen neuen Token
  try {
    final tokenResponse = await http.post(
      Uri.parse('$savedUrl/api/v1/auth/token'),
      headers: {
        'Authorization': 'Basic ' +
            base64Encode(utf8.encode('$savedUsername:$savedPassword')),
        'Accept': 'application/json',
      },
    );

    if (tokenResponse.statusCode == 200) {
      final tokenData = json.decode(tokenResponse.body);
      final newToken = tokenData['token'];
      await prefs.setString('authToken', newToken); // Speichere den neuen Token
      return newToken;
    } else {
      print('Token generation failed with status: ${tokenResponse.statusCode}');
      return null;
    }
  } catch (e) {
    print('Error during token generation: $e');
    return null;
  }
}

Future<String?> sendMobileDeviceCommand(String command, String deviceId,
    {bool preserveDataPlan = false,
    bool disallowProximitySetup = false,
    bool clearActivationLock = false}) async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('url') ?? '';
  final authToken = await getValidToken();
  Uri fullUrl = Uri();
  String? generatedCode;

  if (command == 'DeviceLock') {
    Random random = Random();
    generatedCode = (random.nextInt(900000) + 100000)
        .toString(); // Generiere den 6-stelligen Code
    fullUrl = Uri.parse(
        '$url/JSSResource/computercommands/command/$command/passcode/$generatedCode/id/$deviceId');
  } else if (command == 'EraseDevice') {
    fullUrl = Uri.parse('$url/api/v2/mobile-devices/erase');

    final parameters = {
      "preserveDataPlan": preserveDataPlan,
      "disallowProximitySetup": disallowProximitySetup,
      "clearActivationLock": clearActivationLock
    } as Map<String, dynamic>;

    try {
      final response = await http.post(
        fullUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(parameters),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('EraseDevice command sent successfully!');
        return null;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception occurred: $e');
      return null;
    }
  } else {
    fullUrl = Uri.parse(
        '$url/JSSResource/mobiledevicecommands/command/$command/id/$deviceId');
  }

  try {
    final response = await http.post(
      fullUrl,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
      },
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Command sent successfully!');
      return generatedCode; // Rückgabe des generierten Codes bei DeviceLock
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
      return null;
    }
  } catch (e) {
    print('Exception occurred: $e');
    return null;
  }
}

Future<String?> sendDeviceCommand(String command, String deviceId) async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('url') ?? '';
  final authToken = await getValidToken();
  String? generatedCode;

  if (command == 'EraseComputer') {
    Random random = Random();
    generatedCode = (random.nextInt(900000) + 100000).toString();
    final fullUrl = Uri.parse('$url/api/v1/computer-inventory//erase');

    final parameters = {"pin": generatedCode} as Map<String, dynamic>;

    try {
      final response = await http.post(
        fullUrl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode(parameters),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('EraseDevice command sent successfully!');
        return generatedCode;
      } else {
        print('Error: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      print('Exception occurred: $e');
      return null;
    }
  } else {
    final fullurl = Uri.parse(
        '$url/JSSResource/computercommands/command/$command/id/$deviceId');

    try {
      final response = await http.post(
        fullurl,
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return null;
        print('Command sent successfully!');
      } else {
        return null;
        print('Error: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      return null;
      print('Exception occurred: $e');
    }
  }
}

Future<List> fetchComputerGroups() async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('url') ?? '';
  final authToken = await getValidToken();

  try {
    final response = await http.get(
      Uri.parse('$url/JSSResource/computergroups'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      return data['computer_groups'] as List;
    } else {
      throw Exception('Failed to fetch computer groups');
    }
  } catch (e) {
    print('Error fetching details: $e');
    return [];
  }
}

Future<Map<String, dynamic>?> fetchDevicesGroups() async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('url') ?? '';
  final authToken = await getValidToken();

  try {
    final response = await http.get(
      Uri.parse('$url/JSSResource/mobiledevicegroups'),
      headers: {
        'Authorization': 'Bearer $authToken',
        'Accept': 'application/json',
      },
    );
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      print(response.statusCode);
    }
  } catch (e) {
    print('Error fetching details: $e');
  }
  return null;
}

Future<void> sendUpdateCommand({
  required String objectType,
  required String groupId,
  required String updateAction,
  required String versionType,
  String? specificVersion,
  String? forceInstallLocalDateTime,
}) async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('url') ?? '';
  final authToken = await getValidToken();

  final apiUrl = Uri.parse('$url/api/v1/managed-software-updates/plans/group');

  // Build the parameters map.
  final parameters = {
    "group": {
      "objectType": objectType,
      "groupId": groupId,
    },
    "config": {
      "updateAction": updateAction,
      "versionType": versionType,
      if (specificVersion != null) "specificVersion": specificVersion,
      if (forceInstallLocalDateTime != null)
        "forceInstallLocalDateTime": forceInstallLocalDateTime,
    },
  };

  try {
    final response = await http.post(
      apiUrl,
      headers: {
        'Authorization': 'Bearer $authToken',
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(parameters),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      print('Update command sent successfully!');
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Exception occurred: $e');
  }
}
