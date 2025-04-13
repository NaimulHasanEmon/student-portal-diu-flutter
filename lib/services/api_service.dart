import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

/// Base API URL for DIU Student Portal
const String API_BASE_URL = 'http://software.diu.edu.bd:8006';

/// CORS proxies - generally not needed in mobile apps, but included for parity
const List<String> CORS_PROXIES = [
  'https://corsproxy.io/?',
  'https://cors-anywhere.herokuapp.com/',
  'https://api.allorigins.win/raw?url='
];

/// Check if we're in a release (production) build
bool get isProduction => kReleaseMode;

/// Fetch API with error handling and optional proxy fallback
Future<dynamic> fetchWithErrorHandling(String endpoint, {Map<String, String>? params}) async {
  params ??= {};
  debugPrint('Fetching endpoint: $endpoint, params: $params');

  Uri buildUri(String baseUrl) {
    final uri = Uri.parse('$baseUrl$endpoint').replace(queryParameters: params);
    return uri;
  }

  // Direct API access
  try {
    final uri = buildUri(API_BASE_URL);
    debugPrint('Attempting direct API access: $uri');

    final response = await http.get(uri, headers: {
      'Content-Type': 'application/json',
      'X-Requested-With': 'XMLHttpRequest',
    });

    if (response.statusCode != 200) {
      throw Exception('API error: ${response.statusCode} ${response.reasonPhrase}');
    }

    final data = jsonDecode(response.body);
    debugPrint('Direct API access successful');
    return data;
  } catch (directError) {
    debugPrint('Direct API access failed: $directError');

    // Try CORS proxies (not usually needed in mobile, but preserved for logic completeness)
    dynamic lastError = directError;

    for (final proxy in CORS_PROXIES) {
      try {
        final originalUri = buildUri(API_BASE_URL);
        final proxyUri = Uri.parse('$proxy${Uri.encodeFull(originalUri.toString())}');
        debugPrint('Trying CORS proxy: $proxyUri');

        final response = await http.get(proxyUri, headers: {
          'Content-Type': 'application/json',
        });

        if (response.statusCode != 200) {
          throw Exception('Proxy API error: ${response.statusCode} ${response.reasonPhrase}');
        }

        final data = jsonDecode(response.body);
        debugPrint('CORS proxy successful');
        return data;
      } catch (proxyError) {
        debugPrint('CORS proxy $proxy failed: $proxyError');
        lastError = proxyError;
      }
    }

    throw Exception('Failed to fetch data: ${lastError.toString()}');
  }
}

/// Student API functions
class StudentApi {
  /// Get basic student information
  static Future<dynamic> getStudentInfo(String studentId) async {
    if (studentId.isEmpty) throw Exception('Student ID is required');

    try {
      final data = await fetchWithErrorHandling('/result/studentInfo', params: {'studentId': studentId});
      if (data == null) throw Exception('No student information available');
      return data;
    } catch (e) {
      debugPrint('Error fetching student info: $e');
      rethrow;
    }
  }

  /// Get detailed student information
  static Future<dynamic> getStudentDetails(String studentId) async {
    return getStudentInfo(studentId); // Same endpoint
  }
}

/// Result API functions
class ResultApi {
  /// Get list of semesters
  static Future<List<dynamic>> getSemesters() async {
    try {
      final data = await fetchWithErrorHandling('/result/semesterList');
      if (data is! List) throw Exception('Invalid semester list data');
      return data;
    } catch (e) {
      debugPrint('Error fetching semester list: $e');
      rethrow;
    }
  }

  /// Get result for a specific semester
  static Future<dynamic> getResult(String studentId, String semesterId) async {
    if (studentId.isEmpty) throw Exception('Student ID is required');
    if (semesterId.isEmpty) throw Exception('Semester ID is required');

    try {
      final data = await fetchWithErrorHandling('/result', params: {
        'studentId': studentId,
        'semesterId': semesterId,
        'grecaptcha': '', // Required by the API
      });

      if (data == null) throw Exception('No results available for this semester');
      return data;
    } catch (e) {
      debugPrint('Error fetching results: $e');
      rethrow;
    }
  }
}
