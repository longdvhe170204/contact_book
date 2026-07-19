class Schedule {
  final int id;
  final String className;
  final int dayOfWeek;
  final String period;
  final String subject;
  final String teacher;
  final int? teacherId;
  final String room;
  final String startTime;
  final String endTime;

  Schedule({
    required this.id,
    required this.className,
    required this.dayOfWeek,
    required this.period,
    required this.subject,
    required this.teacher,
    this.teacherId,
    required this.room,
    required this.startTime,
    required this.endTime,
  });

  factory Schedule.fromJson(Map<String, dynamic> json) {
    return Schedule(
      id: json['id'],
      className: json['className'],
      dayOfWeek: json['dayOfWeek'],
      period: json['period'],
      subject: json['subject'],
      teacher: json['teacher'] ?? '',
      teacherId: json['teacherId'] as int?,
      room: json['room'] ?? '',
      startTime: json['startTime'] ?? '',
      endTime: json['endTime'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'className': className,
      'dayOfWeek': dayOfWeek,
      'period': period,
      'subject': subject,
      'teacher': teacher,
      'teacherId': teacherId,
      'room': room,
      'startTime': startTime,
      'endTime': endTime,
    };
  }
}
