import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../../domain/models.dart';

/// Client for the Bioliminal clinical analysis server.
class BioliminalClient {
  BioliminalClient({String? baseUrl, http.Client? httpClient})
    : baseUrl = baseUrl ?? _defaultBaseUrl,
      _client = httpClient ?? http.Client();

  static const String _defaultBaseUrl = String.fromEnvironment(
    'SERVER_URL',
    defaultValue: 'https://bioliminal-demo.aaroncarney.me',
  );

  final String baseUrl;
  final http.Client _client;

  /// Submit a captured session for clinical analysis.
  Future<String> submitSession(SessionPayload payload) async {
    final url = Uri.parse('$baseUrl/sessions');

    // Background serialization to avoid UI jank for large payloads.
    final body = await SessionPayload.serializeAsync(payload);

    try {
      final response = await _client.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['session_id'] as String;
      } else {
        throw Exception(
          'Failed to submit session: ${response.statusCode} ${response.body}',
        );
      }
    } catch (e) {
      developer.log(
        'Server submission error',
        error: e,
        name: 'BioliminalClient',
      );
      rethrow;
    }
  }

  /// Fetch the clinical report for a completed session.
  ///
  /// Returns null while the server is still processing (404). Throws on any
  /// other non-200 status.
  Future<ServerReport?> fetchReport(String sessionId) async {
    final url = Uri.parse('$baseUrl/sessions/$sessionId/report');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        return ServerReport.fromJson(data);
      } else if (response.statusCode == 404) {
        return null;
      } else {
        throw Exception('Failed to fetch report: ${response.statusCode}');
      }
    } catch (e) {
      developer.log('Report fetch error', error: e, name: 'BioliminalClient');
      rethrow;
    }
  }

  void dispose() {
    _client.close();
  }
}
