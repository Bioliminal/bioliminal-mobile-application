import 'dart:convert';
import 'dart:developer' as developer;
import 'package:http/http.dart' as http;
import '../../../domain/models.dart';

/// Client for the Bioliminal clinical analysis server.
class BioliminalClient {
  BioliminalClient({
    this.baseUrl = 'https://api.bioliminal.ai', // Placeholder
    http.Client? httpClient,
  }) : _client = httpClient ?? http.Client();

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
        throw Exception('Failed to submit session: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      developer.log('Server submission error', error: e, name: 'BioliminalClient');
      rethrow;
    }
  }

  /// Fetch the clinical report for a completed session.
  Future<Report?> fetchReport(String sessionId) async {
    final url = Uri.parse('$baseUrl/reports/$sessionId');

    try {
      final response = await _client.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Report.fromJson(data);
      } else if (response.statusCode == 404) {
        // Still processing
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
