import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/agent_response.dart';

class AgentService {
  // Use the hosted URL on Web, or standard local IPs on mobile devices
  static final String _baseUrl = kIsWeb 
      ? Uri.base.origin 
      : 'http://10.62.115.53:8000';

  /// Sends a coding question to the FastAPI backend and returns a structured response.
  static Future<AgentResponse> generate({
    required String question,
    String? threadId,
  }) async {
    final uri = Uri.parse('$_baseUrl/generate');
    final body = jsonEncode({
      'question': question,
      if (threadId != null) 'thread_id': threadId,
    });

    final response = await http
        .post(
          uri,
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(const Duration(minutes: 3));

    if (response.statusCode == 200) {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      return AgentResponse.fromJson(json);
    } else {
      final json = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(json['detail'] ?? 'Unknown error (${response.statusCode})');
    }
  }

  /// Health check — returns true if the backend is reachable.
  static Future<bool> isHealthy() async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/health'))
          .timeout(const Duration(seconds: 5));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }
}
