import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:math';

Future<String> getValidToken() async {
  final prefs = await SharedPreferences.getInstance();
  final savedToken = await getValidToken();
  final savedUrl = prefs.getString('url') ?? '';
  final savedUsername = prefs.getString('username') ?? '';
  final savedPassword = prefs.getString('password') ?? '';

  if (savedToken != null) {
    // Überprüfen, ob der Token gültig ist
    final verifyResponse = await http.get(
      Uri.parse('$savedUrl/api/v1/auth/verify-token'),
      headers: {
        'Authorization': 'Bearer $savedToken',
        'Accept': 'application/json',
      },
    );

    if (verifyResponse.statusCode == 200) {
      return savedToken; // Gültiger Token
    }
  }

  // Neuer Token wird generiert
  final tokenResponse = await http.post(
    Uri.parse('$savedUrl/api/v1/auth/token'),
    headers: {
      'Authorization':
          'Basic ' + base64Encode(utf8.encode('$savedUsername:$savedPassword')),
      'Accept': 'application/json',
    },
  );

  if (tokenResponse.statusCode == 200) {
    final tokenData = json.decode(tokenResponse.body);
    final newToken = tokenData['token'];
    await prefs.setString('authToken', newToken);
    return newToken;
  } else {
    return tokenResponse.statusCode.toString();
  }
}

Future<String?> sendMobileDeviceCommand(String command, String deviceId) async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('url') ?? '';
  final authToken = prefs.getString('authToken') ?? '';
  Uri fullurl = Uri();
  String? generatedCode;

  if (command == 'DeviceLock') {
    Random random = Random();
    generatedCode = (random.nextInt(900000) + 100000)
        .toString(); // Generiere den 6-stelligen Code
    fullurl = Uri.parse(
        '$url/JSSResource/computercommands/command/$command/passcode/$generatedCode/id/$deviceId');
  } else {
    fullurl = Uri.parse(
        '$url/JSSResource/mobiledevicecommands/command/$command/id/$deviceId');
  }

  try {
    final response = await http.post(
      fullurl,
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

Future<void> sendDeviceCommand(String command, String deviceId) async {
  final prefs = await SharedPreferences.getInstance();
  final url = prefs.getString('url') ?? '';
  final authToken = prefs.getString('authToken') ?? '';

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
      print('Command sent successfully!');
    } else {
      print('Error: ${response.statusCode} - ${response.body}');
    }
  } catch (e) {
    print('Exception occurred: $e');
  }
}
