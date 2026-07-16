class Attendance {
  final int id;
  final int studentId;
  final int? teacherId;
  final String? className;
  final String date; // yyyy-MM-dd
  final String status; // PRESENT, ABSENT, LATE
  final String? note;
  final String? subject;

  const Attendance({
    required this.id,
    required this.studentId,
    this.teacherId,
    this.className,
    required this.date,
    required this.status,
    this.note,
    this.subject,
  });

  bool get isPresent => status == 'PRESENT';
  bool get isAbsent => status == 'ABSENT';
  bool get isLate => status == 'LATE';

  String get statusLabel {
    switch (status) {
      case 'PRESENT':
        return 'Có mặt';
      case 'ABSENT':
        return 'Vắng';
      case 'LATE':
        return 'Đi muộn';
      default:
        return status;
    }
  }

  factory Attendance.fromJson(Map<String, dynamic> json) {
    return Attendance(
      id: json['id'] ?? 0,
      studentId: json['studentId'] ?? 0,
      teacherId: json['teacherId'],
      className: json['className']?.toString(),
      date: json['date']?.toString() ?? '',
      status: json['status']?.toString() ?? 'PRESENT',
      note: json['note']?.toString(),
      subject: json['subject']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'studentId': studentId,
      'teacherId': teacherId,
      'className': className,
      'date': date,
      'status': status,
      'note': note,
      'subject': subject,
    };
  }
}
