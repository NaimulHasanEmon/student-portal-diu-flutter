import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/student_model.dart';
import '../services/api_service.dart';

/// Provider to manage student information
class StudentProvider extends ChangeNotifier {
  Student? _student;
  bool _loading = false;
  String? _error;
  
  Student? get student => _student;
  bool get loading => _loading;
  String? get error => _error;
  bool get hasData => _student != null;

  StudentProvider() {
    // Load cached student data on initialization
    _loadCachedStudentData();
  }

  /// Load student data from cache
  Future<void> _loadCachedStudentData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final studentId = prefs.getString('cached_student_id');
      
      if (studentId != null && studentId.isNotEmpty) {
        final cachedData = prefs.getString('cached_student_data');
        
        if (cachedData != null && cachedData.isNotEmpty) {
          try {
            _student = Student.fromJson(
              Map<String, dynamic>.from(jsonDecode(cachedData))
            );
            notifyListeners();
          } catch (e) {
            debugPrint('Error parsing cached student data: $e');
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading cached student data: $e');
    }
  }

  /// Save student data to cache
  Future<void> _cacheStudentData(String studentId, Student student) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_student_id', studentId);
      await prefs.setString('cached_student_data', jsonEncode(student.toJson()));
    } catch (e) {
      debugPrint('Error caching student data: $e');
    }
  }

  /// Fetch student information by ID
  Future<void> fetchStudentInfo(String studentId) async {
    if (studentId.isEmpty) {
      _error = 'Student ID is required';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await StudentApi.getStudentInfo(studentId);
      
      // Debug raw data before conversion
      debugPrint('Raw student data before converting to model: $data');
      
      try {
        _student = Student.fromJson(data);
        _error = null;
        
        // Cache the data
        _cacheStudentData(studentId, _student!);
      } catch (parseError) {
        debugPrint('Error parsing student data to model: $parseError');
        
        // Create fallback student if parsing fails
        _student = Student.fallback(studentId);
        _error = 'Error parsing data: $parseError. Using fallback data.';
      }
    } catch (e) {
      debugPrint('Error fetching student info: $e');
      _error = 'Failed to load student information: ${e.toString()}';
      
      // Create fallback student on API error
      _student = Student.fallback(studentId);
      debugPrint('Using fallback student data');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear student data
  void clearStudentData() async {
    _student = null;
    
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('cached_student_id');
      await prefs.remove('cached_student_data');
    } catch (e) {
      debugPrint('Error clearing cached student data: $e');
    }
    
    notifyListeners();
  }

  /// Get student details (same as info for now)
  Future<void> fetchStudentDetails(String studentId) async {
    await fetchStudentInfo(studentId);
  }
} 