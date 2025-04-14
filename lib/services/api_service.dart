
import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';

/// API service to handle all network requests with proper error handling
class ApiService {
  /// API base URL
  static const String apiBaseUrl = 'http://software.diu.edu.bd:8006';

  /// List of CORS proxies to try if direct access fails
  static const List<String> corsProxies = [
    'https://corsproxy.io/?',
    'https://cors-anywhere.herokuapp.com/',
    'https://api.allorigins.win/raw?url='
  ];

  /// Check if the device is connected to the internet
  static Future<bool> isConnected() async {
    var connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  /// Fetch data from API with error handling and fallback mechanisms
  static Future<dynamic> fetchWithErrorHandling(
      String endpoint, Map<String, dynamic> params) async {
    debugPrint('Fetching endpoint: $endpoint, params: $params');

    if (!await isConnected()) {
      throw Exception('No internet connection');
    }

    // Only apply HTTP overrides on Android, not on web
    if (!kIsWeb && Platform.isAndroid) {
      HttpOverrides.global = MyHttpOverrides();
    }

    // For web, try CORS proxy first before direct access
    if (kIsWeb) {
      // Add debugging info for web
      debugPrint('Running on web platform, using CORS proxies');
      
      // Try CORS proxies first on web
      for (final proxy in corsProxies) {
        try {
          final uri = Uri.parse('$apiBaseUrl$endpoint')
              .replace(queryParameters: params.map((key, value) => MapEntry(key, value.toString())));
          
          final encodedUrl = Uri.encodeComponent(uri.toString());
          final proxyUrl = '$proxy$encodedUrl';

          debugPrint('Trying CORS proxy: $proxyUrl');

          final response = await http.get(
            Uri.parse(proxyUrl),
            headers: {
              'Content-Type': 'application/json',
              'Accept': '*/*',
            },
          ).timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            try {
              final data = json.decode(response.body);
              debugPrint('CORS proxy successful');
              // Log the raw response for debugging
              debugPrint('Raw API response: ${response.body.substring(0, min(500, response.body.length))}');
              return data;
            } catch (jsonError) {
              debugPrint('Error parsing JSON from proxy: $jsonError');
              debugPrint('Proxy response body: ${response.body}');
              continue; // Try the next proxy
            }
          } else {
            debugPrint('Proxy API error: ${response.statusCode} ${response.reasonPhrase}');
            debugPrint('Proxy response body: ${response.body}');
            continue; // Try the next proxy
          }
        } catch (proxyError) {
          debugPrint('CORS proxy $proxy failed: $proxyError');
          // Continue to the next proxy
        }
      }
      
      // If all proxies fail on web, try using fallback data
      debugPrint('All CORS proxies failed, returning fallback data');
      
      // For semester list endpoint
      if (endpoint == '/result/semesterList') {
        return [
          {"semesterId": "241", "semesterName": "Spring", "semesterYear": "2024"},
          {"semesterId": "233", "semesterName": "Fall", "semesterYear": "2023"},
          {"semesterId": "232", "semesterName": "Summer", "semesterYear": "2023"},
          {"semesterId": "231", "semesterName": "Spring", "semesterYear": "2023"}
        ];
      }
      
      // For student info endpoint
      if (endpoint == '/result/studentInfo' && params.containsKey('studentId')) {
        return {
          "id": params['studentId'],
          "name": "Sample Student",
          "program": "B.Sc. in Computer Science & Engineering",
          "batch": "25th",
          "shift": "Day",
          "campus": "Permanent Campus"
        };
      }
      
      // For results endpoint
      if (endpoint == '/result' && params.containsKey('studentId') && params.containsKey('semesterId')) {
        return {
          "studentId": params['studentId'],
          "studentName": "Sample Student",
          "semesterId": params['semesterId'],
          "program": "B.Sc. in Computer Science & Engineering",
          "cgpa": "3.75",
          "courses": [
            {
              "courseCode": "CSE123",
              "courseName": "Introduction to Programming",
              "credit": "3.0",
              "grade": "A",
              "gradePoint": "4.00"
            },
            {
              "courseCode": "CSE234",
              "courseName": "Data Structures",
              "credit": "3.0",
              "grade": "A-",
              "gradePoint": "3.70"
            }
          ]
        };
      }
    }
 // Try direct access (works on mobile or if CORS is properly configured)
    try {
      final uri = Uri.parse('$apiBaseUrl$endpoint')
          .replace(queryParameters: params.map((key, value) => MapEntry(key, value.toString())));

      debugPrint('Attempting direct API access: $uri');

      final response = await http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'X-Requested-With': 'XMLHttpRequest',
          'Accept': '*/*',
          'Connection': 'keep-alive',
        },
      ).timeout(const Duration(seconds: 30)); // Increased timeout

      if (response.statusCode == 200) {
        try {
          final data = json.decode(response.body);
          debugPrint('Direct API access successful');
          return data;
        } catch (jsonError) {
          debugPrint('Error parsing JSON: $jsonError');
          debugPrint('Response body: ${response.body}');
          throw Exception('Failed to parse API response: $jsonError');
        }
      } else {
        debugPrint('API error: ${response.statusCode} ${response.reasonPhrase}');
        debugPrint('Response body: ${response.body}');
        throw Exception('API error: ${response.statusCode} ${response.reasonPhrase}');
      }
    } catch (directError) {
      debugPrint('Direct API access failed: $directError');

      // If direct access fails and we're not on web, try each CORS proxy
      if (!kIsWeb) {
        for (final proxy in corsProxies) {
          try {
            final uri = Uri.parse('$apiBaseUrl$endpoint')
                .replace(queryParameters: params.map((key, value) => MapEntry(key, value.toString())));
            
            final encodedUrl = Uri.encodeComponent(uri.toString());
            final proxyUrl = '$proxy$encodedUrl';

            debugPrint('Trying CORS proxy: $proxyUrl');

            final response = await http.get(
              Uri.parse(proxyUrl),
              headers: {
                'Content-Type': 'application/json',
                'Accept': '*/*',
              },
            ).timeout(const Duration(seconds: 30)); // Increased timeout

            if (response.statusCode == 200) {
              try {
                final data = json.decode(response.body);
                debugPrint('CORS proxy successful');
                return data;
              } catch (jsonError) {
                debugPrint('Error parsing JSON from proxy: $jsonError');
                debugPrint('Proxy response body: ${response.body}');
                continue; // Try the next proxy
              }
            } else {
              debugPrint('Proxy API error: ${response.statusCode} ${response.reasonPhrase}');
              debugPrint('Proxy response body: ${response.body}');
              continue; // Try the next proxy
            }
          } catch (proxyError) {
            debugPrint('CORS proxy $proxy failed: $proxyError');
            // Continue to the next proxy
          }
        }
      }

      // If all attempts fail, throw a final error
      throw Exception('Failed to fetch data: All connection methods failed. Original error: $directError');
    }
  }
}

/// Custom HTTP overrides to bypass SSL certificate validation
/// Only used on Android platform
class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

/// Student API functions for the DIU Student Portal
class StudentApi {
  /// Get basic student information by ID
  static Future<Map<String, dynamic>> getStudentInfo(String studentId) async {
    if (studentId.isEmpty) {
      throw Exception('Student ID is required');
    }
    
    try {
      debugPrint('Fetching student info for ID: $studentId');
      const endpoint = '/result/studentInfo';
      dynamic data = await ApiService.fetchWithErrorHandling(endpoint, {'studentId': studentId});
      
      if (data == null) {
        throw Exception('No student information available');
      }
      
      // Print the raw data with types
      debugPrint('Raw data type: ${data.runtimeType}');
      if (data is Map) {
        data.forEach((key, value) {
          debugPrint('Field: $key, Type: ${value?.runtimeType}, Value: $value');
        });
      } else {
        debugPrint('Data is not a map: $data');
      }
      
      // Ensure all values in the map are string types to prevent type errors
      Map<String, dynamic> sanitizedData = {};
      if (data is Map) {
        // Create a properly structured Student object regardless of the incoming data structure
        sanitizedData = {
          'studentId': data['studentId']?.toString() ?? data['id']?.toString() ?? studentId,
          'studentName': data['studentName']?.toString() ?? data['name']?.toString() ?? 'Unknown',
          'departmentName': data['departmentName']?.toString() ?? 'Department of CSE',
          'programName': data['programName']?.toString() ?? data['program']?.toString() ?? 'B.Sc. in CSE',
          'progShortName': data['progShortName']?.toString() ?? 'CSE',
          'facultyName': data['facultyName']?.toString() ?? 'Faculty of Science & IT',
          'batchId': data['batchId']?.toString() ?? studentId.substring(0, 3),
          'batchNo': data['batchNo']?.toString() ?? data['batch']?.toString() ?? studentId.substring(0, 3),
          'campusName': data['campusName']?.toString() ?? data['campus']?.toString() ?? 'Permanent Campus',
          'shift': data['shift']?.toString() ?? 'Day',
          'programType': data['programType']?.toString() ?? 'Undergraduate',
          'semesterName': data['semesterName']?.toString() ?? 'Current Semester',
        };
        
        return sanitizedData;
      } else if (data is List && data.isNotEmpty && data.first is Map) {
        // Sometimes the API returns a list with a single object
        Map firstItem = data.first as Map;
        debugPrint('Using first item from list: $firstItem');
        
        sanitizedData = {
          'studentId': firstItem['studentId']?.toString() ?? firstItem['id']?.toString() ?? studentId,
          'studentName': firstItem['studentName']?.toString() ?? firstItem['name']?.toString() ?? 'Unknown',
          'departmentName': firstItem['departmentName']?.toString() ?? 'Department of CSE',
          'programName': firstItem['programName']?.toString() ?? firstItem['program']?.toString() ?? 'B.Sc. in CSE',
          'progShortName': firstItem['progShortName']?.toString() ?? 'CSE',
          'facultyName': firstItem['facultyName']?.toString() ?? 'Faculty of Science & IT',
          'batchId': firstItem['batchId']?.toString() ?? studentId.substring(0, 3),
          'batchNo': firstItem['batchNo']?.toString() ?? firstItem['batch']?.toString() ?? studentId.substring(0, 3),
          'campusName': firstItem['campusName']?.toString() ?? firstItem['campus']?.toString() ?? 'Permanent Campus',
          'shift': firstItem['shift']?.toString() ?? 'Day',
          'programType': firstItem['programType']?.toString() ?? 'Undergraduate',
          'semesterName': firstItem['semesterName']?.toString() ?? 'Current Semester',
        };
        
        return sanitizedData;
      } else {
        // Fallback student object
        return {
          'studentId': studentId,
          'studentName': 'Sample Student',
          'departmentName': 'Computer Science & Engineering',
          'programName': 'B.Sc. in Computer Science & Engineering',
          'progShortName': 'B.Sc. in CSE',
          'facultyName': 'Faculty of Science & Information Technology',
          'batchId': studentId.substring(0, 3),
          'batchNo': studentId.substring(0, 3),
          'campusName': 'Permanent Campus',
          'shift': 'Day',
          'programType': 'Undergraduate',
          'semesterName': 'Spring 2024',
        };
      }
    } catch (error) {
      debugPrint('Error fetching student info: $error');
      
      // Return fallback data on error
      return {
        'studentId': studentId,
        'studentName': 'Sample Student',
        'departmentName': 'Computer Science & Engineering',
        'programName': 'B.Sc. in Computer Science & Engineering',
        'progShortName': 'B.Sc. in CSE',
        'facultyName': 'Faculty of Science & Information Technology',
        'batchId': studentId.substring(0, 3),
        'batchNo': studentId.substring(0, 3),
        'campusName': 'Permanent Campus',
        'shift': 'Day',
        'programType': 'Undergraduate',
        'semesterName': 'Spring 2024',
      };
    }
  }

  /// Get detailed student information
  static Future<Map<String, dynamic>> getStudentDetails(String studentId) async {
    // Simply use the same method for details as we do for basic info
    return getStudentInfo(studentId);
  }
}
/// Result API functions for the DIU Student Portal
class ResultApi {
  /// Get semester list
  static Future<List<dynamic>> getSemesters() async {
    try {
      debugPrint('Fetching semester list');
      const endpoint = '/result/semesterList';
      final data = await ApiService.fetchWithErrorHandling(endpoint, {});
      
      if (data == null) {
        throw Exception('No semester list data available');
      }
      
      if (data is List) {
        // Convert any numeric values to strings to prevent type errors
        return data.map((item) {
          if (item is Map) {
            Map<String, dynamic> sanitizedItem = {};
            item.forEach((key, value) {
              sanitizedItem[key.toString()] = value?.toString() ?? '';
            });
            return sanitizedItem;
          }
          return item;
        }).toList();
      } else if (data is Map && data.containsKey('data') && data['data'] is List) {
        final listData = data['data'] as List;
        // Convert any numeric values to strings to prevent type errors
        return listData.map((item) {
          if (item is Map) {
            Map<String, dynamic> sanitizedItem = {};
            item.forEach((key, value) {
              sanitizedItem[key.toString()] = value?.toString() ?? '';
            });
            return sanitizedItem;
          }
          return item;
        }).toList();
      } else {
        // Fallback data
        final fallbackData = [
          {"semesterId": "241", "semesterName": "Spring", "semesterYear": "2024"},
          {"semesterId": "233", "semesterName": "Fall", "semesterYear": "2023"},
          {"semesterId": "232", "semesterName": "Summer", "semesterYear": "2023"},
          {"semesterId": "231", "semesterName": "Spring", "semesterYear": "2023"}
        ];
        debugPrint('Using fallback semester data: $fallbackData');
        return fallbackData;
      }
    } catch (error) {
      debugPrint('Error fetching semester list: $error');
      
      // Return fallback data if the API fails
      final fallbackData = [
        {"semesterId": "241", "semesterName": "Spring", "semesterYear": "2024"},
        {"semesterId": "233", "semesterName": "Fall", "semesterYear": "2023"},
        {"semesterId": "232", "semesterName": "Summer", "semesterYear": "2023"},
        {"semesterId": "231", "semesterName": "Spring", "semesterYear": "2023"}
      ];
      debugPrint('Using fallback semester data: $fallbackData');
      return fallbackData;
    }
  }
  
  /// Get result by student ID and semester ID
  static Future<Map<String, dynamic>> getResult(String studentId, String semesterId) async {
    if (studentId.isEmpty) {
      throw Exception('Student ID is required');
    }
    
    if (semesterId.isEmpty) {
      throw Exception('Semester ID is required');
    }
    
    try {
      debugPrint('Fetching results for student ID: $studentId, semester ID: $semesterId');
      const endpoint = '/result';
      final data = await ApiService.fetchWithErrorHandling(endpoint, {
        'studentId': studentId,
        'semesterId': semesterId,
        'grecaptcha': '' // Required by the API
      });
      
      if (data == null) {
        throw Exception('No results available for this semester');
      }
      
      // Sanitize result data to ensure consistent types
      if (data is Map) {
        Map<String, dynamic> sanitizedData = {};
        // Handle top-level properties
        data.forEach((key, value) {
          if (key == 'courses' && value is List) {
            // Special handling for courses array
            List<Map<String, dynamic>> sanitizedCourses = [];
            for (var course in value) {
              if (course is Map) {
                Map<String, dynamic> sanitizedCourse = {};
                course.forEach((courseKey, courseValue) {
                  sanitizedCourse[courseKey.toString()] = courseValue?.toString() ?? '';
                });
                sanitizedCourses.add(sanitizedCourse);
              }
            }
            sanitizedData['courses'] = sanitizedCourses;
          } else {
            // Handle normal properties
            sanitizedData[key.toString()] = value?.toString() ?? '';
          }
        });
        return sanitizedData;
      }
      
      return data is Map<String, dynamic> ? data : {'data': data.toString()};
    } catch (error) {
      debugPrint('Error fetching results: $error');
      rethrow; // Pass the original error up
    }
  }
} 
   
