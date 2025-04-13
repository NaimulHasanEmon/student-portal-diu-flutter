/// Model class for Semester information
class Semester {
  final String semesterId;
  final String semesterName;
  final String semesterYear;

  Semester({
    required this.semesterId,
    required this.semesterName,
    required this.semesterYear,
  });

  factory Semester.fromJson(Map<String, dynamic> json) {
    // Debug the incoming JSON
    print('Semester.fromJson - Raw json: $json');
    
    // Helper function to safely convert any value to string
    String safeToString(dynamic value) {
      if (value == null) return '';
      return value.toString();
    }
    
    return Semester(
      semesterId: safeToString(json['semesterId']),
      semesterName: safeToString(json['semesterName']),
      semesterYear: safeToString(json['semesterYear']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'semesterId': semesterId,
      'semesterName': semesterName,
      'semesterYear': semesterYear,
    };
  }

  String get fullName => '$semesterName $semesterYear';

  @override
  String toString() => fullName;
} 