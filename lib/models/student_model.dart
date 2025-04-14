/// Model class for Student information
class Student {
  final String studentId;
  final String studentName;
  final String departmentName;
  final String programName;
  final String progShortName;
  final String facultyName;
  final String batchId;
  final String batchNo;
  final String campusName;
  final String shift;
  final String programType;
  final String semesterName;

  Student({
    required this.studentId,
    required this.studentName,
    required this.departmentName,
    required this.programName,
    required this.progShortName,
    required this.facultyName,
    required this.batchId,
    required this.batchNo,
    required this.campusName,
    required this.shift,
    required this.programType,
    required this.semesterName,
  });

  factory Student.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    print('Student.fromJson - Raw json: $json');
    
    // Helper function to safely convert any value to string
    String safeToString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }
    
    return Student(
      studentId: safeToString(json['studentId']),
      studentName: safeToString(json['studentName']),
      departmentName: safeToString(json['departmentName']),
      programName: safeToString(json['programName']),
      progShortName: safeToString(json['progShortName']),
      facultyName: safeToString(json['facultyName']),
      batchId: safeToString(json['batchId']),
      batchNo: safeToString(json['batchNo']),
      campusName: safeToString(json['campusName']),
      shift: safeToString(json['shift']),
      programType: safeToString(json['programType']),
      semesterName: safeToString(json['semesterName']),
    );
  }

  // Create a placeholder/fallback student with the given ID
  factory Student.fallback(String studentId) {
    return Student(
      studentId: studentId,
      studentName: "Sample Student",
      departmentName: "Computer Science & Engineering",
      programName: "B.Sc. in Computer Science & Engineering",
      progShortName: "B.Sc. in CSE",
      facultyName: "Faculty of Science & Information Technology",
      batchId: studentId.substring(0, 3),
      batchNo: studentId.substring(0, 3),
      campusName: "Permanent Campus",
      shift: "Day",
      programType: "Undergraduate",
      semesterName: "Spring 2024",
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'studentId': studentId,
      'studentName': studentName,
      'departmentName': departmentName,
      'programName': programName,
      'progShortName': progShortName,
      'facultyName': facultyName,
      'batchId': batchId,
      'batchNo': batchNo,
      'campusName': campusName,
      'shift': shift,
      'programType': programType,
      'semesterName': semesterName,
    };
  }
} 