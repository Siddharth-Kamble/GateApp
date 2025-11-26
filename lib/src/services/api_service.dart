// import 'dart:convert';
// import 'package:flutter_application_1/src/core/constant.dart';
// import 'package:http/http.dart' as http;
// import '../core/constants.dart';

// class ApiService {
// final http.Client client;
// ApiService({http.Client? client}) : client = client ?? http.Client();

// Future<http.Response> post(String path, Map<String, dynamic> body) async {
// final url = Uri.parse('$apiBase$path');
// final resp = await client.post(url, body: jsonEncode(body), headers: {'Content-Type': 'application/json'});
// return resp;
// }

// Future<http.Response> get(String path) async {
// final url = Uri.parse('$apiBase$path');
// final resp = await client.get(url);
// return resp;
// }
// }
import 'dart:convert';
import 'package:flutter_application_1/src/core/constant.dart';
import 'package:http/http.dart' as http;

class ApiService {
  final http.Client client;
  ApiService({http.Client? client}) : client = client ?? http.Client();

  Future<http.Response> post(String path, Map<String, dynamic> body) async {
    final url = Uri.parse('$apiBase$path');
    final resp = await client.post(
      url,
      body: jsonEncode(body),
      headers: {'Content-Type': 'application/json'},
    );
    return resp;
  }

  Future<http.Response> get(String path) async {
    final url = Uri.parse('$apiBase$path');
    final resp = await client.get(url);
    return resp;
  }
}
