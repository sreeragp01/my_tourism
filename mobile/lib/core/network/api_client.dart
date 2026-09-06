import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/api_constants.dart';

class ApiClient {
  final http.Client _httpClient = http.Client();

  Future<String?> _getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  Future<void> saveTokens(String access, String refresh) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', access);
    await prefs.setString('refresh_token', refresh);
  }

  Future<http.Response> get(String endpoint) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConstants.devBaseUrl}$endpoint');
    return _httpClient.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await _getAccessToken();
    final url = Uri.parse('${ApiConstants.devBaseUrl}$endpoint');
    return _httpClient.post(
      url,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    );
  }
}
