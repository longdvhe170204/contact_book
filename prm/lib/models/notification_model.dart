class NotificationModel {
  final int id;
  final String title;
  final String content;
  final String sender;
  final String category; // IMPORTANT, SCHOOL, FEE
  final String createdAt;
  final String date;
  bool isRead; // Local state for read/unread

  NotificationModel({
    required this.id,
    required this.title,
    required this.content,
    required this.sender,
    required this.category,
    required this.createdAt,
    required this.date,
    this.isRead = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'],
      title: json['title'],
      content: json['content'],
      sender: json['sender'],
      category: json['category'],
      createdAt: json['createdAt'],
      date: json['date'],
      isRead: json['isRead'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'content': content,
      'sender': sender,
      'category': category,
      'createdAt': createdAt,
      'date': date,
      'isRead': isRead,
    };
  }
}
