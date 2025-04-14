/// Model class for individual course result
class CourseResult {
  final String courseCode;
  final String courseName;
  final double credit;
  final String grade;
  final double gradePoint;

  CourseResult({
    required this.courseCode,
    required this.courseName,
    required this.credit,
    required this.grade,
    required this.gradePoint,
  });

  factory CourseResult.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    print('CourseResult.fromJson - Raw json: $json');
    
    // Helper function for safe double conversion
    double safeToDouble(dynamic value) {
      if (value == null) return 0.0;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Remove any comma or whitespace before parsing
        final cleanString = value.replaceAll(',', '').trim();
        return double.tryParse(cleanString) ?? 0.0;
      }
      return 0.0;
    }
    
    return CourseResult(
      courseCode: json['courseCode']?.toString() ?? '',
      courseName: json['courseName']?.toString() ?? '',
      credit: safeToDouble(json['credit']),
      grade: json['grade']?.toString() ?? '',
      gradePoint: safeToDouble(json['gradePoint']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'credit': credit,
      'grade': grade,
      'gradePoint': gradePoint,
    };
  }
}

/// Model class for all semester result information
class Result {
  final String? studentId;
  final String? semesterId;
  final double? semesterGpa;
  final double? cgpa;
  final double? completedCredits;
  final List<Course>? courses;

  Result({
    this.studentId,
    this.semesterId,
    this.semesterGpa,
    this.cgpa,
    this.completedCredits,
    this.courses,
  });

  factory Result.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    print('Result.fromJson - Raw json: $json');
    
    // Helper function for safe double conversion
    double? safeToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Remove any comma or whitespace before parsing
        final cleanString = value.replaceAll(',', '').trim();
        return double.tryParse(cleanString);
      }
      return null;
    }
    
    List<Course>? coursesList;
    if (json['courses'] != null) {
      try {
        coursesList = (json['courses'] as List)
            .map((courseJson) => Course.fromJson(courseJson is Map<String, dynamic> 
                ? courseJson 
                : {'courseCode': courseJson.toString()}))
            .toList();
      } catch (e) {
        print('Error parsing courses list: $e');
        coursesList = [];
      }
    }

    return Result(
      studentId: json['studentId']?.toString(),
      semesterId: json['semesterId']?.toString(),
      semesterGpa: safeToDouble(json['semesterGpa']),
      cgpa: safeToDouble(json['cgpa']),
      completedCredits: safeToDouble(json['completedCredits']),
      courses: coursesList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'semesterId': semesterId,
      'semesterGpa': semesterGpa,
      'cgpa': cgpa,
      'completedCredits': completedCredits,
      'courses': courses?.map((course) => course.toJson()).toList(),
    };
  }

  double get totalCredits {
    double total = 0.0;
    for (var course in courses ?? []) {
      total += course.credit ?? 0.0;
    }
    return total;
  }

  double get totalGradePoints {
    double total = 0.0;
    for (var course in courses ?? []) {
      total += (course.credit ?? 0.0) * (course.gradePoint ?? 0.0);
    }
    return total;
  }
}

class Course {
  final String? courseCode;
  final String? courseName;
  final double? credit;
  final String? grade;
  final double? gradePoint;

  Course({
    this.courseCode,
    this.courseName,
    this.credit,
    this.grade,
    this.gradePoint,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    print('Course.fromJson - Raw json: $json');
    
    // Helper function for safe double conversion
    double? safeToDouble(dynamic value) {
      if (value == null) return null;
      if (value is double) return value;
      if (value is int) return value.toDouble();
      if (value is String) {
        // Remove any comma or whitespace before parsing
        final cleanString = value.replaceAll(',', '').trim();
        return double.tryParse(cleanString);
      }
      return null;
    }
    
    return Course(
      courseCode: json['courseCode']?.toString(),
      courseName: json['courseName']?.toString(),
      credit: safeToDouble(json['credit']) ?? 0.0,
      grade: json['grade']?.toString(),
      gradePoint: safeToDouble(json['gradePoint']) ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'courseCode': courseCode,
      'courseName': courseName,
      'credit': credit,
      'grade': grade,
      'gradePoint': gradePoint,
    };
  }
} 