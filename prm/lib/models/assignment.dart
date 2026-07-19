class Assignment {
  final int id;
  final String className;
  final String subject;
  final String title;
  final String description;
  final String teacher;
  final int? teacherId;
  final String dueDate;
  final String createdAt;
  final String? fileUrl;

  Assignment({
    required this.id,
    required this.className,
    required this.subject,
    required this.title,
    required this.description,
    required this.teacher,
    this.teacherId,
    required this.dueDate,
    required this.createdAt,
    this.fileUrl,
  });

  factory Assignment.fromJson(Map<String, dynamic> json) {
    return Assignment(
      id: json['id'],
      className: json['className'],
      subject: json['subject'],
      title: json['title'],
      description: json['description'] ?? '',
      teacher: json['teacher'] ?? '',
      teacherId: json['teacherId'] as int?,
      dueDate: json['dueDate'] ?? '',
      createdAt: json['createdAtCustom'] ?? json['createdAt'] ?? '',
      fileUrl: json['fileUrl'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'className': className,
      'subject': subject,
      'title': title,
      'description': description,
      'teacher': teacher,
      'teacherId': teacherId,
      'dueDate': dueDate,
      'createdAt': createdAt,
      'fileUrl': fileUrl,
    };
  }
}
