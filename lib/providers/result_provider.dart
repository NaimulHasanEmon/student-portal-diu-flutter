import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/result_model.dart';
import '../models/semester_model.dart';
import '../services/api_service.dart';

/// Provider to manage result information
class ResultProvider extends ChangeNotifier {
  Result? _result;
  List<Semester> _semesters = [];
  bool _loading = false;
  bool _loadingSemesters = false;
  String? _error;
  String? _semesterError;
  
  Result? get result => _result;
  List<Semester> get semesters => _semesters;
  bool get loading => _loading;
  bool get loadingSemesters => _loadingSemesters;
  String? get error => _error;
  String? get semesterError => _semesterError;
  bool get hasData => _result != null;
  bool get hasSemesters => _semesters.isNotEmpty;

  ResultProvider() {
    // Load cached data on initialization
    _loadCachedSemesters();
  }

  /// Load semesters from cache
  Future<void> _loadCachedSemesters() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cachedData = prefs.getString('cached_semesters');
      
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          final List<dynamic> semestersJson = jsonDecode(cachedData);
          _semesters = semestersJson
              .map((json) => Semester.fromJson(json))
              .toList();
          notifyListeners();
        } catch (e) {
          debugPrint('Error parsing cached semesters: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached semesters: $e');
    }
  }

  /// Cache semesters to local storage
  Future<void> _cacheSemesters(List<Semester> semesters) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final semestersJson = semesters.map((s) => s.toJson()).toList();
      await prefs.setString('cached_semesters', jsonEncode(semestersJson));
    } catch (e) {
      debugPrint('Error caching semesters: $e');
    }
  }

  /// Load cached result
  Future<void> _loadCachedResult(String studentId, String semesterId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_result_${studentId}_$semesterId';
      final cachedData = prefs.getString(key);
      
      if (cachedData != null && cachedData.isNotEmpty) {
        try {
          _result = Result.fromJson(jsonDecode(cachedData));
          notifyListeners();
        } catch (e) {
          debugPrint('Error parsing cached result: $e');
        }
      }
    } catch (e) {
      debugPrint('Error loading cached result: $e');
    }
  }

  /// Cache result to local storage
  Future<void> _cacheResult(String studentId, String semesterId, Result result) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_result_${studentId}_$semesterId';
      await prefs.setString(key, jsonEncode(result.toJson()));
    } catch (e) {
      debugPrint('Error caching result: $e');
    }
  }

  /// Fetch the list of semesters
  Future<void> fetchSemesters() async {
    _loadingSemesters = true;
    _semesterError = null;
    notifyListeners();

    try {
      final List<dynamic> semestersList = await ResultApi.getSemesters();
      _semesters = semestersList
          .map((json) => Semester.fromJson(json as Map<String, dynamic>))
          .toList();
      _semesterError = null;
      
      // Cache the semesters
      _cacheSemesters(_semesters);
    } catch (e) {
      debugPrint('Error fetching semesters: $e');
      _semesterError = 'Failed to load semesters: ${e.toString()}';
      
      // Provide fallback data
      _semesters = [
        Semester(semesterId: "241", semesterName: "Spring", semesterYear: "2024"),
        Semester(semesterId: "233", semesterName: "Fall", semesterYear: "2023"),
        Semester(semesterId: "232", semesterName: "Summer", semesterYear: "2023"),
        Semester(semesterId: "231", semesterName: "Spring", semesterYear: "2023")
      ];
      _semesterError = null; // Clear error since we're using fallback data
    } finally {
      _loadingSemesters = false;
      notifyListeners();
    }
  }

  /// Fetch result by student ID and semester ID
  Future<void> fetchResult(String studentId, String semesterId) async {
    if (studentId.isEmpty) {
      _error = 'Student ID is required';
      notifyListeners();
      return;
    }

    if (semesterId.isEmpty) {
      _error = 'Semester ID is required';
      notifyListeners();
      return;
    }

    _loading = true;
    _error = null;
    notifyListeners();

    // Try to load from cache first
    await _loadCachedResult(studentId, semesterId);

    try {
      final data = await ResultApi.getResult(studentId, semesterId);
      _result = Result.fromJson(data);
      _error = null;
      
      // Cache the result
      _cacheResult(studentId, semesterId, _result!);
    } catch (e) {
      debugPrint('Error fetching result: $e');
      _error = 'Failed to load result: ${e.toString()}';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Clear all result data
  void clearResultData() async {
    _result = null;
    notifyListeners();
  }
  
  /// Retry loading semesters
  Future<void> retryLoadingSemesters() async {
    await fetchSemesters();
  }
  
  /// Get semester name from ID
  String getSemesterInfo(String semesterId) {
    final semester = _semesters.firstWhere(
      (s) => s.semesterId == semesterId,
      orElse: () => Semester(
        semesterId: semesterId,
        semesterName: "Unknown",
        semesterYear: "Semester"
      ),
    );
    
    return semester.fullName;
  }
} 