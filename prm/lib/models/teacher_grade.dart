class TeacherGrade {
  final int? gradeId;
  final int studentId;
  final String studentName;
  final String className;
  final String subject;
  final int semester;
  final List<double> tx15;
  final List<double> tx1tiet;
  final double? giuaKy;
  final double? cuoiKy;
  final double? average;

  const TeacherGrade({
    required this.studentId,
    required this.studentName,
    required this.className,
    required this.subject,
    required this.semester,
    this.gradeId,
    this.tx15 = const [],
    this.tx1tiet = const [],
    this.giuaKy,
    this.cuoiKy,
    this.average,
  });

  factory TeacherGrade.fromJson(Map<String, dynamic> json) {
    List<double> parseList(dynamic input) {
      if (input is List) {
        return input.map((item) => (item as num).toDouble()).toList();
      }
      return const [];
    }

    double? parseDouble(dynamic input) {
      if (input == null) {
        return null;
      }
      if (input is num) {
        return input.toDouble();
      }
      return double.tryParse(input.toString());
    }

    return TeacherGrade(
      gradeId: json['gradeId'] as int?,
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName'] ?? '',
      className: json['className'] ?? '',
      subject: json['subject'] ?? '',
      semester: json['semester'] ?? 1,
      tx15: parseList(json['tx15']),
      tx1tiet: parseList(json['tx1tiet']),
      giuaKy: parseDouble(json['giuaKy']),
      cuoiKy: parseDouble(json['cuoiKy']),
      average: parseDouble(json['average']),
    );
  }
}