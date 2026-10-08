import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class ChatApiService {

  static const String _baseUrl = String.fromEnvironment(
 	 'API_BASE_URL',
	  defaultValue: 'http://10.0.2.2:8000',
	);

  Future<String> sendMessage(List<Map<String, dynamic>> messages) async {
    final uri = Uri.parse('$_baseUrl/chat');

    try {
      if (kDebugMode) {
        print('REQUEST URL: $uri');
        print('REQUEST BODY: ${jsonEncode({'messages': messages})}');
      }

      final response = await http
          .post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json',
            },
            body: jsonEncode({
              'messages': messages,
            }),
          )
          .timeout(const Duration(seconds: 120));

      if (kDebugMode) {
        print('STATUS CODE: ${response.statusCode}');
        print('RESPONSE BODY: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        if (data is Map<String, dynamic>) {
          final reply = data['reply'];

          if (reply != null && reply.toString().trim().isNotEmpty) {
            return reply.toString();
          }

          return 'No reply returned from server.';
        }

        return 'Unexpected server response.';
      }

      return _handleHttpError(response.statusCode, response.body);
    } on TimeoutException {
      return 'The request timed out. Please try again.';
    } on FormatException {
      return 'The server returned an invalid response.';
    } on http.ClientException catch (e) {
      return 'Could not connect to the server: $e';
    } catch (e) {
      return 'Unexpected error: $e';
    }
  }

  String _handleHttpError(int statusCode, String body) {
    if (statusCode == 404) {
      return 'The /chat endpoint was not found. Check the API base URL.';
    }

    if (statusCode == 422) {
      return 'The request format is not accepted by the server.';
    }

    if (statusCode == 500) {
      return 'The server had an internal error.';
    }

    return 'Request failed. Status code: $statusCode\n$body';
  }
}