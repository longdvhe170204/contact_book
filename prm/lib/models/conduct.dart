class Conduct {
  final int id;
  final int studentId;
  final String? studentName;
  final int? teacherId;
  final String? teacherName;
  final String? className;
  final int month;
  final int year;
  final String conductRating; // EXCELLENT, GOOD, AVERAGE, WEAK
  final String? comment;

  const Conduct({
    required this.id,
    required this.studentId,
    this.studentName,
    this.teacherId,
    this.teacherName,
    this.className,
    required this.month,
    required this.year,
    required this.conductRating,
    this.comment,
  });

  String get ratingLabel {
    switch (conductRating) {
      case 'EXCELLENT':
        return 'Xuất sắc';
      case 'GOOD':
        return 'Tốt';
      case 'AVERAGE':
        return 'Khá';
      case 'WEAK':
        return 'Yếu';
      default:
        return conductRating;
    }
  }

  factory Conduct.fromJson(Map<String, dynamic> json) {
    return Conduct(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      studentName: json['studentName']?.toString(),
      teacherId: json['teacherId'],
      teacherName: json['teacherName']?.toString(),
      className: json['className']?.toString(),
      month: json['month'] ?? 0,
      year: json['year'] ?? 0,
      conductRating: json['conductRating']?.toString() ?? 'GOOD',
      comment: json['comment']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'studentName': studentName,
      'teacherId': teacherId,
      'teacherName': teacherName,
      'className': className,
      'month': month,
      'year': year,
      'conductRating': conductRating,
      'comment': comment,
    };
  }
}
